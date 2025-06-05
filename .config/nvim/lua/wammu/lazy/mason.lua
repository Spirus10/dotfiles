return {
    {
        "mason-org/mason.nvim",
        opts = {}
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
        },

        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup()
        end
    },
}
