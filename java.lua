-- ~/.config/nvim/lua/plugins/java.lua
-- Complete Java and Spring Boot setup for LazyVim
-- Includes: LSP, Debugging, Testing, and Lombok support
-- Just drop this file in your plugins folder and restart Neovim

return {
	-- Ensure Java is in treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		opts = { ensure_installed = { "java" } },
	},

	-- Install Java tools via Mason
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"jdtls",
				"java-debug-adapter",
				"java-test",
			},
		},
	},

	-- Setup nvim-jdtls
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		opts = function()
			return {
				-- How to find the root dir for a given filename
				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),

				-- How to find the project name for a given root dir
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

				-- How to run jdtls with Lombok support
				cmd = {
					vim.fn.exepath("jdtls"),
					"--jvm-arg=-javaagent:" .. vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar",
				},

				full_cmd = function(opts)
					local fname = vim.api.nvim_buf_get_name(0)
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
			-- Find and load the debug adapter bundles
			local function get_bundles()
				local bundles = {}
				local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

				-- Java debug adapter
				local java_debug_path = mason_path
					.. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
				for _, bundle in ipairs(vim.split(vim.fn.glob(java_debug_path), "\n")) do
					if vim.fn.filereadable(bundle) == 1 then
						table.insert(bundles, bundle)
					end
				end

				-- Java test adapter
				local java_test_path = mason_path .. "/java-test/extension/server/*.jar"
				for _, bundle in ipairs(vim.split(vim.fn.glob(java_test_path), "\n")) do
					if vim.fn.filereadable(bundle) == 1 then
						table.insert(bundles, bundle)
					end
				end

				return bundles
			end

			-- Attach jdtls for each java buffer
			local function attach_jdtls()
				local bundles = get_bundles()

				local config = {
					cmd = opts.full_cmd(opts),
					root_dir = opts.root_dir,
					settings = opts.settings,
					init_options = {
						bundles = bundles,
					},
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
				}

				require("jdtls").start_or_attach(config)

				-- Setup DAP for debugging
				require("jdtls").setup_dap({ hotcodereplace = "auto" })
				require("jdtls.dap").setup_dap_main_class_configs()

				-- Java-specific keymaps
				local buf = vim.api.nvim_get_current_buf()

				-- Refactoring
				vim.keymap.set(
					"n",
					"<leader>co",
					require("jdtls").organize_imports,
					{ buffer = buf, desc = "Organize Imports" }
				)
				vim.keymap.set(
					"n",
					"<leader>cxv",
					require("jdtls").extract_variable_all,
					{ buffer = buf, desc = "Extract Variable" }
				)
				vim.keymap.set(
					"n",
					"<leader>cxc",
					require("jdtls").extract_constant,
					{ buffer = buf, desc = "Extract Constant" }
				)
				vim.keymap.set(
					"v",
					"<leader>cxm",
					[[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
					{ buffer = buf, desc = "Extract Method" }
				)
				vim.keymap.set(
					"v",
					"<leader>cxv",
					[[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
					{ buffer = buf, desc = "Extract Variable" }
				)
				vim.keymap.set(
					"v",
					"<leader>cxc",
					[[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
					{ buffer = buf, desc = "Extract Constant" }
				)

				-- Testing
				vim.keymap.set(
					"n",
					"<leader>tc",
					require("jdtls.dap").test_class,
					{ buffer = buf, desc = "Test Class" }
				)
				vim.keymap.set(
					"n",
					"<leader>tm",
					require("jdtls.dap").test_nearest_method,
					{ buffer = buf, desc = "Test Method" }
				)
			end

			-- Attach on FileType
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

	-- Configure nvim-dap for debugging
	{
		"mfussenegger/nvim-dap",
		opts = function()
			-- Debug keymaps (these work automatically with LazyVim)
			local dap = require("dap")

			-- You can add custom configurations here if needed
			dap.configurations.java = dap.configurations.java or {}
		end,
	},

	-- Avoid duplicate LSP setup
	{
		"neovim/nvim-lspconfig",
		opts = {
			setup = {
				jdtls = function()
					return true
				end,
			},
		},
	},
}
