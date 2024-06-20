local function moveCursorPos(offset_x, offset_y)
    local x, y = term.getCursorPos()
    if offset_x == nil then
        term.setCursorPos(1, y + offset_y)
    elseif offset_y == nil then
        term.setCursorPos(x + offset_x, 1)
    else
        term.setCursorPos(x + offset_x, y + offset_y)
    end
end

local function get_text(prompt, default)
    local term_color = term.getTextColor()
    local input
    while true do
        term.setTextColor(term_color)
        print(prompt)
        term.setTextColor(colors.white)
        io.write(">> ")
        if default ~= nil then
            term.setTextColor(colors.lightGray)
            io.write(default)
            moveCursorPos(nil, 0)
            moveCursorPos(3, 0)
            term.setTextColor(colors.white)

            while true do
                local _, key, _ = os.pullEvent("key")
                local key_name = keys.getName(key)
                if key_name == "enter" then
                    input = default
                    break
                elseif string.find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", key_name, 0, true) ~= nil or key_name == "slash" or key_name == "minus" then
                    moveCursorPos(nil, 0)
                    term.clearLine()
                    io.write(">> ")
                    input = io.read()
                    break
                end
            end
        else
            input = io.read()
        end
        moveCursorPos(nil, 0)
        term.clearLine()
        term.setTextColor(colors.orange)
        print(input)
        term.setTextColor(term_color)
        return input
    end
end

local function get_decision(prompt, default)
    local term_color = term.getTextColor()
    local decision
    while true do
        term.setTextColor(term_color)
        io.write(prompt)
        term.setTextColor(colors.orange)
        io.write(" ("..(default and "Y" or "y").."/"..(default == false and "N" or "n")..")\n")
        term.setTextColor(colors.white)
        io.write(">> ")
        if default ~= nil then
            term.setTextColor(colors.lightGray)
            io.write(default and "y" or "n")
            moveCursorPos(-1, 0)
            term.setTextColor(colors.white)
        end
        local _, key, _ = os.pullEvent("key")
        decision = keys.getName(key)
        if decision == "enter" then
            if default ~= nil then
                decision = default
                break
            else
                term.setTextColor(colors.red)
                moveCursorPos(nil, 0)
                print("No default value provided - please press y or n")
            end
        elseif decision == "y" then
            decision = true
            break
        elseif decision == "n" then
            decision = false
            break
        else
            term.setTextColor(colors.red)
            moveCursorPos(nil, 0)
            print("Please choose an option")
        end
    end
    moveCursorPos(nil, 0)
    term.clearLine()
    term.setTextColor(decision and colors.lime or colors.red)
    print(decision and "y" or "n")
    term.setTextColor(term_color)
    return decision
end

shell.setDir("/")
term.setTextColor(colors.blue)

local tets_path = get_text("Path to install tets at:", "/bin/tets")
tets_path = "/"..fs.combine(tets_path)

if fs.exists(tets_path) then
    local do_reset = get_decision("A tets installation already exists at the selected path. Do you wish to reinstall?", -1)
    if not do_reset then
        shell.exit()
    else
        fs.delete(tets_path)
    end
end

fs.makeDir(tets_path.."/".."packages")

local do_global = get_decision("Do you want tets to install packages globally? (Programs will have to be ran through \"tets run\" to resolve tets dependencies, but it will save on disk space. When enabled, you can still install dependencies locally through \"tets localize\". This can be changed later.)", -1)

local tetsconfig = fs.open(tets_path.."/".."tetsconfig.json", "w")
tetsconfig.write(textutils.serializeJSON({sources = {"https://raw.githubusercontent.com/Jakub-Wilk/cappack/master/tetsfile.json",}, global_first = do_global}))
tetsconfig.close()

local tets_script = http.get("https://raw.githubusercontent.com/Jakub-Wilk/tets/master/tets.lua").readAll()
local tets = fs.open(tets_path.."/".."tets.lua", "w")
tets.write(tets_script)
tets.close()

if fs.exists("/startup") then
    print("A startup script already exists; please add "..tets_path.."/".." to your path manually!")
else
    local startup = fs.open("/startup", "w")
    startup.write("shell.setPath(shell.path()..\":"..tets_path.."/".."\")")
end

local do_restart = get_decision("Installation successful. The computer needs to be restarted to use tets. Would you like to restart now?")
if do_restart then
    os.reboot()
else
    print("Thank you for installing tets!")
end