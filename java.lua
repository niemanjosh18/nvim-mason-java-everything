-- ~/.config/nvim/lua/plugins/java.lua
-- Complete Java and Spring Boot setup for LazyVim
-- Includes: LSP, Debugging, Testing, and Lombok support
-- Drop this file in lua/plugins/ and restart Neovim

return {
	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "java" })
		end,
	},

	-- Mason: Install Java tools
	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"jdtls",
				"java-debug-adapter",
				"java-test",
			})
		end,
	},

	-- Java LSP
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
		dependencies = { "folke/which-key.nvim" },
		opts = function()
			return {
				-- Find root directory
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),

				-- Project name function
				project_name = function(root_dir)
					return root_dir and vim.fs.basename(root_dir)
				end,

				-- Config and workspace directories
				jdtls_config_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
				end,
				jdtls_workspace_dir = function(project_name)
					return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
				end,

				-- Command to run jdtls with Lombok
				cmd = {
					vim.fn.exepath("jdtls"),
					"--jvm-arg=-javaagent:" .. vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar",
				},

				full_cmd = function(opts)
					local root_dir = opts.root_dir
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

				-- jdtls settings
				settings = {
					java = {
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
					},
				},
			}
		end,

		config = function(_, opts)
			-- Function to get debug adapter bundles
			local function get_bundles()
				local bundles = {}
				local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

				-- Java Debug Adapter
				local java_debug_path = mason_path
					.. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
				for _, bundle in ipairs(vim.split(vim.fn.glob(java_debug_path), "\n")) do
					if vim.fn.filereadable(bundle) == 1 then
						table.insert(bundles, bundle)
					end
				end

				-- Java Test Adapter
				local java_test_path = mason_path .. "/java-test/extension/server/*.jar"
				for _, bundle in ipairs(vim.split(vim.fn.glob(java_test_path), "\n")) do
					if vim.fn.filereadable(bundle) == 1 then
						table.insert(bundles, bundle)
					end
				end

				return bundles
			end

			-- Attach jdtls to buffer
			local function attach_jdtls()
				local bundles = get_bundles()

				-- Get capabilities from LazyVim's cmp setup
				local capabilities = vim.lsp.protocol.make_client_capabilities()
				local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
				if has_cmp then
					capabilities = cmp_lsp.default_capabilities(capabilities)
				end

				local config = {
					cmd = opts.full_cmd(opts),
					root_dir = opts.root_dir,
					settings = opts.settings,
					init_options = {
						bundles = bundles,
					},
					capabilities = capabilities,
				}

				-- Start or attach jdtls
				require("jdtls").start_or_attach(config)

				-- Setup DAP if available
				local has_dap, jdtls_dap = pcall(require, "jdtls.dap")
				if has_dap then
					jdtls_dap.setup_dap_main_class_configs()
					require("jdtls").setup_dap({ hotcodereplace = "auto" })
				end

				-- Setup keymaps with which-key
				local wk = require("which-key")
				wk.add({
					{ "<leader>cj", group = "java", buffer = 0 },
					{
						"<leader>cjo",
						function()
							require("jdtls").organize_imports()
						end,
						desc = "Organize Imports",
						buffer = 0,
					},
					{
						"<leader>cjv",
						function()
							require("jdtls").extract_variable()
						end,
						desc = "Extract Variable",
						buffer = 0,
						mode = { "n", "v" },
					},
					{
						"<leader>cjc",
						function()
							require("jdtls").extract_constant()
						end,
						desc = "Extract Constant",
						buffer = 0,
						mode = { "n", "v" },
					},
					{
						"<leader>cjm",
						function()
							require("jdtls").extract_method(true)
						end,
						desc = "Extract Method",
						buffer = 0,
						mode = "v",
					},
					{ "<leader>cjt", group = "test", buffer = 0 },
					{
						"<leader>cjtc",
						function()
							require("jdtls.dap").test_class()
						end,
						desc = "Test Class",
						buffer = 0,
					},
					{
						"<leader>cjtm",
						function()
							require("jdtls.dap").test_nearest_method()
						end,
						desc = "Test Method",
						buffer = 0,
					},
				})
			end

			-- Attach on Java FileType
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = attach_jdtls,
			})

			-- Attach if already in a java buffer
			if vim.bo.filetype == "java" then
				attach_jdtls()
			end
		end,
	},

	-- Prevent nvim-lspconfig from setting up jdtls
	{
		"neovim/nvim-lspconfig",
		opts = {
			setup = {
				jdtls = function()
					return true -- avoid duplicate setup
				end,
			},
		},
	},
}
