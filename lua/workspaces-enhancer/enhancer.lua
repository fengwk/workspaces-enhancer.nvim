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

-- 获取真实路径到工作空间名称的映射
local function get_path_to_ws_name_map()
  local ws_list = ws.get()
  if ws_list == nil or #ws_list == 0 then
    return
  end
  local path_to_ws_name = {}
  for _, item in pairs(ws_list) do
    path_to_ws_name[item.path] = item.name
  end
  return path_to_ws_name
end

-- 获取指定path路径的可加载工作空间，如果存在多个只获取里path最近的一个
local function get_can_loaded_ws(path)
  -- 获取路径到工作空间名称的映射
  local path_to_ws_name = get_path_to_ws_name_map()
  if path_to_ws_name == nil then
    return nil, nil
  end
  -- 检查是否有匹配的工作空间
  local can_loaded_ws_name = nil
  local can_loaded_ws_path = nil
  utils.iter_path_until_root(path, function(cur_path)
    local ws_name = path_to_ws_name[cur_path .. utils.fs_separator]
    if ws_name ~= nil then
      can_loaded_ws_name = ws_name
      can_loaded_ws_path = cur_path
      return false
    end
    return true
  end)
  return can_loaded_ws_name, can_loaded_ws_path
end

local function build_record_file(ws_dir, ws_name)
  local record_name = "buf#" .. ws_name
  local record_file = utils.fs_concat({ ws_dir, record_name })
  return record_file
end

-- 获取path路径的记录文件，如果path路径没有相应工作空间则返回nil
local function get_record_file(ws_dir, path)
  local can_loaded_ws_name, _ = get_can_loaded_ws(path)
  if can_loaded_ws_name == nil then
    return
  end
  return build_record_file(ws_dir, can_loaded_ws_name), can_loaded_ws_name
end

-- 打开当前工作空间记录的缓冲区
local function reload_ws_buf(ws_dir)
  local record_file, ws_name = get_record_file(ws_dir, vim.fn.getcwd())
  if record_file == nil or record_file == "" then
    return
  end
  local buf_path = utils.read_file(record_file)
  if buf_path ~= nil then
    vim.schedule(function()
      pcall(function()
        -- 如果缓冲区冲突此处会出现异常，使用pcall忽略
        vim.api.nvim_command("edit " .. buf_path)
      end)
    end)
  end
end

-- 自动加载当前工作空间
local function auto_load_ws(ws_dir)
  local buf_path = vim.fn.expand("%:p")
  if buf_path == nil or buf_path == "" then -- 只在无名缓冲区自动加载

    local line_count = vim.api.nvim_buf_line_count(0)
    if line_count == 1 and vim.cmd("echo getline(1)") == "" then -- 仅在无内容时加载
      reload_ws_buf(ws_dir)
    end
  end
end

-- 记录当前工作空间的缓冲区
local function record_ws_buf(ws_dir)
  local buf_path = vim.fn.expand("%:p")
  if buf_path == nil or buf_path == "" or utils.is_uri(buf_path) or utils.is_not_file_ft() then
    return
  end

  local record_file = get_record_file(ws_dir, buf_path)
  if record_file ~= nil then
    utils.write_file(record_file, buf_path)
  end

  -- 如果当前缓冲区并非工作空间cwd则进行切换
  local ws_name, ws_path = get_can_loaded_ws(buf_path)
  if ws_name ~= nil and ws_path ~= nil then
    vim.api.nvim_command("cd " .. ws_path) -- 切换根目录
    local t_ok, nvim_tree_api = pcall(require, "nvim-tree.api")
    if t_ok then
      nvim_tree_api.tree.change_root(ws_path) -- 主动修改nvim-tree root，否则切换会出现问题
      -- 自动切换到nvim-tree聚焦到打开的文件
      local ok_finders_find_file, finders_find_file = pcall(require, "nvim-tree.actions.finders.find-file")
      if ok_finders_find_file then
        finders_find_file.fn(buf_path)
      end
    end
  end
end

-- 删除记录缓存
local function remove_ws_buf(ws_dir, name)
  local record_file = build_record_file(ws_dir, name)
  if utils.exists_file(record_file) then
    os.remove(record_file)
  end
end

return {
  reload_ws_buf = reload_ws_buf,
  auto_load_ws = auto_load_ws,
  record_ws_buf = record_ws_buf,
  remove_ws_buf = remove_ws_buf,
}
