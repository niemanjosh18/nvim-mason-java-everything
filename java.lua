-- ~/.config/nvim/lua/plugins/java.lua
-- Java and Spring Boot development setup for Neovim with Lazy.nvim

return {
	-- Mason: Tool installer for LSP servers, DAP servers, linters, formatters
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"jdtls", -- Java Language Server
					"lemminx", -- XML support for pom.xml and Spring XML configs
				},
			})
		end,
	},

	-- nvim-jdtls: Enhanced Java support with Eclipse JDT Language Server
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			-- This configuration will be triggered when opening Java files
			local jdtls = require("jdtls")

			-- Determine OS for jdtls configuration
			local home = os.getenv("HOME")
			local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
			local workspace_dir = home
				.. "/.local/share/nvim/jdtls-workspace/"
				.. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

			-- Determine platform-specific config
			local os_config = "linux"
			if vim.fn.has("mac") == 1 then
				os_config = "mac"
			elseif vim.fn.has("win32") == 1 then
				os_config = "win"
			end

			local config = {
				cmd = {
					"java",
					"-Declipse.application=org.eclipse.jdt.ls.core.id1",
					"-Dosgi.bundles.defaultStartLevel=4",
					"-Declipse.product=org.eclipse.jdt.ls.core.product",
					"-Dlog.protocol=true",
					"-Dlog.level=ALL",
					"-Xmx1g",
					"--add-modules=ALL-SYSTEM",
					"--add-opens",
					"java.base/java.util=ALL-UNNAMED",
					"--add-opens",
					"java.base/java.lang=ALL-UNNAMED",
					"-jar",
					vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
					"-configuration",
					jdtls_path .. "/config_" .. os_config,
					"-data",
					workspace_dir,
				},

				root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),

				settings = {
					java = {
						eclipse = {
							downloadSources = true,
						},
						configuration = {
							updateBuildConfiguration = "interactive",
						},
						maven = {
							downloadSources = true,
						},
						implementationsCodeLens = {
							enabled = true,
						},
						referencesCodeLens = {
							enabled = true,
						},
						references = {
							includeDecompiledSources = true,
						},
						format = {
							enabled = true,
						},
					},
					signatureHelp = { enabled = true },
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
						useBlocks = true,
					},
				},

				init_options = {
					bundles = {},
				},

				on_attach = function(client, bufnr)
					-- Keybindings for Java-specific features
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "<leader>co", jdtls.organize_imports, opts)
					vim.keymap.set("n", "<leader>cv", jdtls.extract_variable, opts)
					vim.keymap.set(
						"v",
						"<leader>cv",
						[[<ESC><CMD>lua require('jdtls').extract_variable(true)<CR>]],
						opts
					)
					vim.keymap.set("n", "<leader>cc", jdtls.extract_constant, opts)
					vim.keymap.set(
						"v",
						"<leader>cc",
						[[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
						opts
					)
					vim.keymap.set("v", "<leader>cm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], opts)

					-- General LSP keybindings
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			}

			-- Start jdtls
			jdtls.start_or_attach(config)
		end,
	},

	-- DAP: Debug Adapter Protocol for debugging
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
		},
	},

	-- DAP UI: Better debugging interface
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dap, dapui = require("dap"), require("dapui")

			dapui.setup()

			-- Automatically open/close DAP UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Debugging keybindings
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Conditional Breakpoint" })
		end,
	},

	-- Spring Boot Language Server for annotation completion and properties support
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Note: Install spring-boot-tools via Mason with :MasonInstall spring-boot-tools
			-- This provides Spring Boot annotations, properties, and YAML completion
			lspconfig.spring_boot.setup({
				capabilities = capabilities,
				filetypes = { "java" },
				on_attach = function(client, bufnr)
					-- Spring Boot specific keybindings
					local opts = { noremap = true, silent = true, buffer = bufnr }
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				end,
			})
		end,
	},

	-- Treesitter for better syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "java", "lua", "vim", "vimdoc", "query" },
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},
}
