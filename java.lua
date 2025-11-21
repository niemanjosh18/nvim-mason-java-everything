-- ~/.config/nvim/lua/plugins/java.lua
-- Simple Java development for LazyVim
-- LSP, autocomplete, go-to-definition, Spring Boot support
-- Just drop this file in lua/plugins/ and restart Neovim

return {
	-- Configure Mason to use nvim-java registry
	{
		"williamboman/mason.nvim",
		opts = {
			registries = {
				"github:nvim-java/mason-registry",
				"github:mason-org/mason-registry",
			},
		},
	},

	-- nvim-java setup
	{
		"nvim-java/nvim-java",
		dependencies = {
			"nvim-java/lua-async-await",
			"nvim-java/nvim-java-core",
			"MunifTanjim/nui.nvim",
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
		},
		config = function()
			require("java").setup({
				-- Auto-install JDK if needed
				jdk = {
					auto_install = true,
				},

				-- Enable Spring Boot support
				spring_boot_tools = {
					enable = true,
				},

				-- Disable testing and debugging features
				java_test = {
					enable = false,
				},

				java_debug_adapter = {
					enable = false,
				},

				notifications = {
					dap = false,
				},
			})
		end,
	},

	-- Setup jdtls through lspconfig
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				jdtls = {},
			},
			setup = {
				jdtls = function()
					require("lspconfig").jdtls.setup({})
					return true
				end,
			},
		},
	},
}
