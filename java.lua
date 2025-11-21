-- ~/.config/nvim/lua/plugins/java.lua
-- Java and Spring Boot development setup for LazyVim

return {
	-- Add Java to treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "java" })
			end
		end,
	},

	-- Configure Mason to install Java tools
	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"jdtls",
				"java-debug-adapter",
				"java-test",
				"spring-boot-tools",
				"lemminx", -- XML support for pom.xml
			})
		end,
	},

	-- Setup nvim-jdtls
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
		dependencies = {
			"folke/which-key.nvim",
		},
		opts = function()
			local mason_registry = require("mason-registry")
			local lombok_jar = mason_registry.get_package("jdtls"):get_install_path() .. "/lombok.jar"

			return {
				-- How to find the root dir for a given filename. The default comes from
				-- lspconfig which provides a function specifically for java projects.
				root_dir = require("lspconfig.server_configurations.jdtls").default_config.root_dir,

				-- How to find the project name for a given root dir.
				project_name = function(root_dir)
					return root_dir and vim.fs.basename(root_dir)
				end,

				-- Where are the config and workspace dirs for a project?
				jdtls_config_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
				end,
				jdtls_workspace_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
				end,

				-- How to run jdtls. This can be overridden to a full java command-line
				-- if the Python wrapper script doesn't suffice.
				cmd = {
					vim.fn.exepath("jdtls"),
					string.format("--jvm-arg=-javaagent:%s", lombok_jar),
				},
				full_cmd = function(opts)
					local fname = vim.api.nvim_buf_get_name(0)
					local root_dir = opts.root_dir(fname)
					local project_name = opts.project_name(root_dir)
					local cmd = vim.deepcopy(opts.cmd)
					if project_name then
						vim.list_extend(cmd, {
							"-configuration",
							opts.jdtls_config_dir(project_name),
							"-data",
							opts.jdtls_workspace_dir(project_name),
						})
					end
					return cmd
				end,

				-- These depend on nvim-dap, but can additionally be disabled by setting false here.
				dap = { hotcodereplace = "auto", config_overrides = {} },
				dap_main = {},
				test = true,
				settings = {
					java = {
						inlayHints = {
							parameterNames = {
								enabled = "all",
							},
						},
						signatureHelp = { enabled = true },
						contentProvider = { preferred = "fernflower" },
						completion = {
							favoriteStaticMembers = {
								"org.hamcrest.MatcherAssert.assertThat",
								"org.hamcrest.Matchers.*",
								"org.hamcrest.CoreMatchers.*",
								"org.junit.jupiter.api.Assertions.*",
								"java.util.Objects.requireNonNull",
								"java.util.Objects.requireNonNullElse",
								"org.mockito.Mockito.*",
							},
							filteredTypes = {
								"com.sun.*",
								"io.micrometer.shaded.*",
								"java.awt.*",
								"jdk.*",
								"sun.*",
							},
							importOrder = {
								"java",
								"javax",
								"org",
								"com",
							},
						},
						sources = {
							organizeImports = {
								starThreshold = 9999,
								staticStarThreshold = 9999,
							},
						},
						codeGeneration = {
							toString = {
								template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
							},
							hashCodeEquals = {
								useJava7Objects = true,
							},
							useBlocks = true,
						},
						configuration = {
							runtimes = {
								-- Configure your Java runtimes here if needed
								-- {
								--   name = "JavaSE-17",
								--   path = "/path/to/jdk-17",
								-- },
							},
						},
					},
				},
			}
		end,
		config = function(_, opts)
			-- Find the extra bundles that should be passed on the jdtls command-line
			-- if nvim-dap is enabled with java debug/test.
			local mason_registry = require("mason-registry")
			local bundles = {} ---@type string[]
			if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
				local java_dbg_pkg = mason_registry.get_package("java-debug-adapter")
				local java_dbg_path = java_dbg_pkg:get_install_path()
				local jar_patterns = {
					java_dbg_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
				}
				-- java-test also depends on java-debug-adapter.
				if opts.test and mason_registry.is_installed("java-test") then
					local java_test_pkg = mason_registry.get_package("java-test")
					local java_test_path = java_test_pkg:get_install_path()
					vim.list_extend(jar_patterns, {
						java_test_path .. "/extension/server/*.jar",
					})
				end
				for _, jar_pattern in ipairs(jar_patterns) do
					for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
						table.insert(bundles, bundle)
					end
				end
			end

			local function attach_jdtls()
				local fname = vim.api.nvim_buf_get_name(0)

				-- Configuration can be augmented and overridden by opts.jdtls
				local config = require("lspconfig.server_configurations.jdtls").default_config

				-- Find the project root based on the current file
				local root_dir = opts.root_dir(fname)
				local project_name = opts.project_name(root_dir)
				local cmd = opts.full_cmd(opts)
				local jdtls_config_dir = opts.jdtls_config_dir(project_name)

				-- Setup workspace dir
				local jdtls_workspace_dir = opts.jdtls_workspace_dir(project_name)

				config.cmd = cmd
				config.root_dir = root_dir
				config.init_options = {
					bundles = bundles,
				}
				config.settings = opts.settings
				config.capabilities = require("cmp_nvim_lsp").default_capabilities()

				-- Existing server will be reused if the root_dir matches.
				require("jdtls").start_or_attach(config)

				-- Setup keymaps
				local wk = require("which-key")
				wk.add({
					{
						mode = { "n", "v" },
						buffer = vim.api.nvim_get_current_buf(),
						{ "<leader>cx", group = "extract" },
						{ "<leader>cxv", require("jdtls").extract_variable_all, desc = "Extract Variable" },
						{ "<leader>cxc", require("jdtls").extract_constant, desc = "Extract Constant" },
						{ "gs", require("jdtls").super_implementation, desc = "Goto Super" },
						{ "gS", require("jdtls.tests").goto_subjects, desc = "Goto Subjects" },
						{ "<leader>co", require("jdtls").organize_imports, desc = "Organize Imports" },
					},
					{
						mode = "v",
						buffer = vim.api.nvim_get_current_buf(),
						{ "<leader>cx", group = "extract" },
						{
							"<leader>cxm",
							[[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
							desc = "Extract Method",
						},
						{
							"<leader>cxv",
							[[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
							desc = "Extract Variable",
						},
						{
							"<leader>cxc",
							[[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
							desc = "Extract Constant",
						},
					},
				})

				-- Setup DAP if enabled
				if opts.dap and LazyVim.has("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
					-- custom init for Java debugger
					require("jdtls").setup_dap(opts.dap)
					require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)

					-- Java Test require Java debugger to work
					if opts.test and mason_registry.is_installed("java-test") then
						-- custom keymaps for Java test runner
						wk.add({
							{ "<leader>t", group = "test" },
							{
								"<leader>tt",
								function()
									require("jdtls.dap").test_class({
										config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides
											or nil,
									})
								end,
								desc = "Run All Test",
							},
							{
								"<leader>tr",
								function()
									require("jdtls.dap").test_nearest_method({
										config_overrides = type(opts.test) ~= "boolean" and opts.test.config_overrides
											or nil,
									})
								end,
								desc = "Run Nearest Test",
							},
							{ "<leader>tT", require("jdtls.dap").pick_test, desc = "Run Test" },
						})
					end
				end

				-- User can set additional keymaps in opts.on_attach
				if opts.on_attach then
					opts.on_attach(vim.api.nvim_get_current_buf())
				end
			end

			-- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
			-- depending on filetype, so this autocmd doesn't run for the first file.
			-- For that, we call directly below.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = attach_jdtls,
			})

			-- Setup the java language server to attach to the current buffer,
			-- if the filetype is java.
			if vim.bo.filetype == "java" then
				attach_jdtls()
			end
		end,
	},

	-- Spring Boot Language Server
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				spring_boot = {
					filetypes = { "java" },
				},
			},
			setup = {
				jdtls = function()
					return true -- avoid duplicate setup by nvim-lspconfig
				end,
			},
		},
	},
}
