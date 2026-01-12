return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      -- Fix per far funzionare OSC52 anche con NeoTree
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Funzione per copiare via OSC 52
      local function copy(lines, _)
        require("vim.ui.clipboard.osc52").copy(lines)
      end

      -- Funzione per incollare via OSC 52 (Nota: molti terminali lo bloccano per sicurezza)
      local function paste()
        return require("vim.ui.clipboard.osc52").paste()
      end

      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = copy,
          ["*"] = copy,
        },
        paste = {
          ["+"] = paste,
          ["*"] = paste,
        },
      }
      
      -- Opzionale: sincronizza automaticamente la clipboard di sistema
      vim.opt.clipboard = "unnamedplus"
    end,
  },
}
