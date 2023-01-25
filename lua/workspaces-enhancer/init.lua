local function setup(config)
  local ok_ws, ws = pcall(require, "workspaces")
  if not ok_ws then
    vim.notify("Workspaces enhancer can not work, because workspaces can not be requried.", vim.log.levels.WARN)
    return
  end

  local ok_utils, utils = pcall(require, "fengwk.utils")
  if not ok_utils then
    vim.notify("Workspaces enhancer can not work, because fengwk.utils can not be requried.", vim.log.levels.WARN)
    return
  end

  local enhancer = require("workspaces-enhancer.enhancer")

  local ws_dir = config.ws_dir
  if not ws_dir then
    ws_dir = config.path or utils.fs_concat({ vim.fn.stdpath("cache"), "workspaces" })
  end
  utils.ensure_mkdir(ws_dir)
  config = vim.tbl_deep_extend("force", config, {
    path = utils.fs_concat({ ws_dir, "ws" }),
  })
  if not config.hooks then
    config.hooks = {}
  end
  if not config.hooks.add then
    config.hooks.add = {}
  end
  if not config.hooks.remove then
    config.hooks.remove = {}
  end
  if not config.hooks.open then
    config.hooks.open = {}
  end
  table.insert(config.hooks.add, function()
    enhancer.record_ws_buf(ws_dir)
  end)
  table.insert(config.hooks.remove, function(name, _, _)
    enhancer.remove_ws_buf(ws_dir, name)
  end)
  table.insert(config.hooks.open, function()
    enhancer.reload_ws_buf(ws_dir)
  end)
  ws.setup(config)

  vim.api.nvim_create_augroup("user_workspaces", { clear = true })
  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = "user_workspaces",
    pattern = "*",
    callback = function()
      enhancer.auto_load_ws(ws_dir)
    end
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = "user_workspaces",
    pattern = "*",
    callback = function()
      enhancer.record_ws_buf(ws_dir)
    end
  })

end

return {
  setup = setup,
}
