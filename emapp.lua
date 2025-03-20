local function fetchFileFromGitHub(repo, path)
    local url = "https://api.github.com/repos/" .. repo .. "/contents/" .. path
    local headers = {
        ["User-Agent"] = "ComputerCraft"
    }
    local response = http.get(url, headers)
    if response then
        local data = response.readAll()
        response.close()
        local content = textutils.unserializeJSON(data)
        if content and content.content then
            local decodedContent = textutils.urlDecode(content.content)
            return decodedContent
        elseif content and content.type == "dir" then
            return content
        end
    end
    return nil
end

local function fetchPackageList()
    local repo = "Gandshack/pakpak-packages"
    local path = "packages.json"
    local content = fetchFileFromGitHub(repo, path)
    if content then
        return textutils.unserializeJSON(content)
    end
    return nil
end

local function installFile(repo, path, installPath)
    local content = fetchFileFromGitHub(repo, path)
    if content then
        local file = fs.open(installPath, "w")
        file.write(content)
        file.close()
        print("Installed " .. path .. " to " .. installPath)
    else
        print("Failed to fetch " .. path)
    end
end

local function installDirectory(repo, path, installPath)
    local content = fetchFileFromGitHub(repo, path)
    if content then
        for _, item in ipairs(content) do
            local itemPath = path .. "/" .. item.name
            local itemInstallPath = installPath .. "/" .. item.name
            if item.type == "file" then
                installFile(repo, itemPath, itemInstallPath)
            elseif item.type == "dir" then
                fs.makeDir(itemInstallPath)
                installDirectory(repo, itemPath, itemInstallPath)
            end
        end
    else
        print("Failed to fetch directory " .. path)
    end
end

local function installPackage(repo, path, installPath)
    if fs.exists(installPath) then
        fs.delete(installPath)
    end
    fs.makeDir(installPath)
    installDirectory(repo, path, installPath)
end

local function main()
    local args = { ... }
    if #args < 2 or args[1] ~= "install" then
        print("Usage: pakpak install [appname]")
        return
    end

    local appName = args[2]
    local packageList = fetchPackageList()
    if not packageList then
        print("Failed to fetch package list")
        return
    end

    local packageInfo = packageList[appName]
    if not packageInfo then
        print("Package not found: " .. appName)
        return
    end

    local repo = packageInfo.repo
    local path = packageInfo.path
    local installPath = packageInfo.installPath

    installPackage(repo, path, installPath)
end

main()
