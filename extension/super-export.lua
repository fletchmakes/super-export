-- MIT License

-- Copyright (c) 2021 David Fletcher

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- helper methods
-- create an error alert and exit the dialog
local function create_error(str, dialog, exit)
    app.alert(str)
    if (exit == 1) then dialog:close() end
end

-- create a confirmation dialog and wait for the user to confirm
local function create_confirm(str)
    local confirm = Dialog("Confirm?")

    confirm:label {
        id="text",
        text=str
    }

    confirm:button {
        id="cancel",
        text="Cancel",
        onclick=function()
            confirm:close()
        end
    }

    confirm:button {
        id="confirm",
        text="Confirm",
        onclick=function()
            confirm:close()
        end
    }

    -- always give the user a way to exit
    local function cancelWizard(confirm)
        confirm:close()
    end

    -- show to grab centered coordinates
    confirm:show{ wait=true }

    return confirm.data.confirm
end

-- always give the user a way to exit
local function cancelWizard(dlg)
    dlg:close()
end

local function processExport(props)
    local sprite = app.activeSprite

    -- give a warning to the user
    local confirm = create_confirm("On the following window, set the percentage at 100%.")

    if (confirm) then
        -- start a new transaction
        app.transaction(function () 
            -- calculate the new values
            local newwidth = sprite.width * (props.percentage / 100)
            local newheight = sprite.height * (props.percentage / 100)
        
            -- resize the sprite
            sprite:resize(newwidth, newheight)

            -- save a copy of the sprite
            app.command.SaveFileCopyAs { ["useUI"]=true }
        end) -- end transaction

        -- undo changes to the current file so that it's state is preserved
        app.command.Undo()
    end
end

--------------------------
-- declare Dialog object
--------------------------
local function mainWindow()
    local dialog = Dialog("Super Export")

    local sprite = app.activeSprite
    local s_width = sprite.width
    local s_height = sprite.height

    dialog:number {
        id="percentage",
        label="Resize Percentage: ",
        text=tostring(100),
        decimals=0,
        onchange=function()
            -- update the projected pixel ratios
            local newwidth = math.floor(s_width * (dialog.data.percentage / 100))
            local newheight = math.floor(s_height * (dialog.data.percentage / 100))

            dialog:modify {
                id="ratio_width",
                text=tostring(newwidth).."px"
            }

            dialog:modify {
                id="ratio_height",
                text=tostring(newheight).."px"
            }
        end
    }

    dialog:separator {
        id="ratio_display"
    }

    dialog:label {
        id="ratio_width",
        label="New Width:",
        text=tostring(s_width).."px"
    }

    dialog:label {
        id="ratio_height",
        label="New Height:",
        text=tostring(s_height).."px"
    }

    dialog:separator {
        id="footer"
    }

    dialog:button {
        id="cancel",
        text="Cancel",
        onclick=function()
            dialog:close()
        end
    }

    dialog:button {
        id="confirm",
        text="Confirm",
        onclick=function()
            local props = dialog.data
            -- check to see if the percentage is valid
            if (props.percentage < 100) then
                create_error("The percentage must be >= 100%", dialog, 0)
                return
            end

            -- show the dialog to the user
            dialog:close()
            processExport(props)
        end
    }

    return dialog
end

-- display the dialog to the user
mainWindow():show{ wait=true }
