-- ~/.config/nvim/lua/plugins/java.lua
-- Painless Java development for LazyVim using nvim-java
-- Just drop this file in lua/plugins/ and restart Neovim
-- Everything installs automatically!

return {
	-- IMPORTANT: Enable DAP core extra for debugging support
	{ import = "lazyvim.plugins.extras.dap.core" },

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

	-- nvim-java: The easy way to do Java in Neovim
	{
		"nvim-java/nvim-java",
		dependencies = {
			"nvim-java/lua-async-await",
			"nvim-java/nvim-java-core",
			"nvim-java/nvim-java-test",
			"nvim-java/nvim-java-dap",
			"MunifTanjim/nui.nvim",
			"neovim/nvim-lspconfig",
			"mfussenegger/nvim-dap",
			"williamboman/mason.nvim",
		},
		config = function()
			require("java").setup({
				-- Everything is auto-configured, but you can customize here if needed
				root_markers = {
					"settings.gradle",
					"settings.gradle.kts",
					"pom.xml",
					"build.gradle",
					"mvnw",
					"gradlew",
					"build.gradle",
					"build.gradle.kts",
					".git",
				},

				-- Automatically install JDK if not present
				jdk = {
					auto_install = true,
				},

				-- Enable all the goodies
				java_test = {
					enable = true,
				},

				java_debug_adapter = {
					enable = true,
				},

				spring_boot_tools = {
					enable = true,
				},

				notifications = {
					dap = true,
				},
			})
		end,
	},

	-- Setup LSP after nvim-java
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				jdtls = {
					-- Your jdtls configuration goes here
				},
			},
			setup = {
				jdtls = function()
					require("lspconfig").jdtls.setup({
						-- Settings for jdtls
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
					})
					return true
				end,
			},
		},
	},

	-- Keymaps for Java development
	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				{ "<leader>cj", group = "java", icon = "☕" },
			},
		},
	},

	-- Add Java keymaps
	{
		"nvim-java/nvim-java",
		keys = {
			-- Build & Clean
			{ "<leader>cjb", "<cmd>JavaBuildBuildWorkspace<cr>", desc = "Build Workspace" },
			{ "<leader>cjc", "<cmd>JavaBuildCleanWorkspace<cr>", desc = "Clean Workspace" },

			-- Run & Debug Application
			{ "<leader>cjr", "<cmd>JavaRunnerRunMain<cr>", desc = "Run Main" },
			{ "<leader>cjs", "<cmd>JavaRunnerStopMain<cr>", desc = "Stop Main" },
			{ "<leader>cjl", "<cmd>JavaRunnerToggleLogs<cr>", desc = "Toggle Logs" },

			-- Testing
			{ "<leader>cjt", group = "test" },
			{ "<leader>cjtc", "<cmd>JavaTestRunCurrentClass<cr>", desc = "Test Class" },
			{ "<leader>cjtm", "<cmd>JavaTestRunCurrentMethod<cr>", desc = "Test Method" },
			{ "<leader>cjtd", "<cmd>JavaTestDebugCurrentClass<cr>", desc = "Debug Test Class" },
			{ "<leader>cjtn", "<cmd>JavaTestDebugCurrentMethod<cr>", desc = "Debug Test Method" },
			{ "<leader>cjtr", "<cmd>JavaTestViewLastReport<cr>", desc = "View Last Report" },

			-- Refactoring
			{ "<leader>cje", group = "extract/refactor" },
			{ "<leader>cjev", "<cmd>JavaRefactorExtractVariable<cr>", desc = "Extract Variable", mode = { "n", "v" } },
			{
				"<leader>cjea",
				"<cmd>JavaRefactorExtractVariableAllOccurrence<cr>",
				desc = "Extract Variable (All)",
				mode = { "n", "v" },
			},
			{ "<leader>cjec", "<cmd>JavaRefactorExtractConstant<cr>", desc = "Extract Constant", mode = { "n", "v" } },
			{ "<leader>cjem", "<cmd>JavaRefactorExtractMethod<cr>", desc = "Extract Method", mode = { "n", "v" } },
			{ "<leader>cjef", "<cmd>JavaRefactorExtractField<cr>", desc = "Extract Field", mode = { "n", "v" } },

			-- Profiles & Settings
			{ "<leader>cjp", "<cmd>JavaProfile<cr>", desc = "Open Profiles" },
			{ "<leader>cji", "<cmd>JavaSettingsChangeRuntime<cr>", desc = "Change JDK Runtime" },
			{ "<leader>cjd", "<cmd>JavaDapConfig<cr>", desc = "Force DAP Config" },
		},
	},
}
