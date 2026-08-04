local M = {}

--- runs `cmd` and trims trailing newline
---@param cmd string
---@return string output
---@return boolean ok
function M.shell(cmd)
    local output = vim.fn.system(cmd):gsub("\n$", "")
    return output, vim.v.shell_error == 0
end

---@return string? root
function M.jj_root()
    local root, ok = M.shell("jj workspace root 2>/dev/null")
    if ok and root ~= "" then
        return root
    end
    return nil
end

---@return string? root
function M.git_root()
    local root, ok = M.shell("git rev-parse --show-toplevel 2>/dev/null")
    if ok and root ~= "" then
        return root
    end
    return nil
end

--- detects which vcs the cwd is inside of, preferring jj over git
---@return "jj" | "git" | nil kind
---@return string? root
function M.detect()
    local jj_root = M.jj_root()
    if jj_root then
        return "jj", jj_root
    end

    local git_root = M.git_root()
    if git_root then
        return "git", git_root
    end

    return nil, nil
end

return M
