local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local CODE_ACTION = methods.internal.CODE_ACTION

return h.make_builtin({
    name = "statix",
    method = CODE_ACTION,
    filetypes = { "nix" },
    generator_opts = {
        command = "statix",
        args = { "check", "--format=json", "--", "$FILENAME" },
        format = "json",
        to_temp_file = true,
        from_stderr = true,
        on_output = function(params)
            local actions = {}
            for _, r in ipairs(params.output.report) do
                for _, d in ipairs(r.diagnostics) do
                    if d.suggestion ~= vim.NIL then
                        local from = d.suggestion.at.from
                        local to = d.suggestion.at.to
                        if params.row >= from.line and params.row <= to.line then
                            local mess = "Fix: " .. d.message
                            local fix = {}
                            for l in vim.gsplit(d.suggestion.fix, "\n") do
                                table.insert(fix, l)
                            end
                            table.insert(actions, {
                                title = mess,
                                action = function()
                                    vim.api.nvim_buf_set_text(
                                        params.bufnr,
                                        from.line - 1,
                                        from.column - 1,
                                        to.line - 1,
                                        to.column - 1,
                                        fix
                                    )
                                end,
                            })
                        end
                    end
                end
            end
            return actions
        end,
    },
    factory = h.generator_factory,
})
