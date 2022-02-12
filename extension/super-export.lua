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

local function calculate_export_size(original_width, original_height, resize_percentage)
    return {
        width = original_width * resize_percentage / 100,
        height = original_height * resize_percentage / 100,
    }
end

local function selection_only_checkbox_text(selection_width, selection_height)
    return "(" .. tostring(selection_width) .. "px x " .. tostring(selection_height) .. "px)"
end

local function label_ratio_width_text(width)
    return tostring(math.floor(width)) .. "px"
end

local function label_ratio_height_text(height)
    return tostring(math.floor(height)) .. "px"
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
            -- crop sprite to selection, if chosen to do so
            if (props.selection_only) then
                sprite:crop()
            end
            
            -- calculate the new values
            local export_size = calculate_export_size(sprite.width, sprite.height, props.percentage)
        
            -- resize the sprite
            sprite:resize(export_size.width, export_size.height)

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
    local sprite_width = sprite.width
    local sprite_height = sprite.height
    local selection_width = sprite.selection.bounds.width
    local selection_height = sprite.selection.bounds.height

    dialog:number {
        id="percentage",
        label="Resize Percentage: ",
        text=tostring(100),
        decimals=0,
        onchange=function()
            -- update the projected pixel ratios
            local new_export_size = calculate_export_size(sprite_width, sprite_height, dialog.data.percentage)
            if (dialog.data.selection_only) then
                new_export_size = calculate_export_size(selection_width, selection_height, dialog.data.percentage)
            end
            
            dialog:modify {
                id="ratio_width",
                text=label_ratio_width_text(new_export_size.width)
            }
            
            dialog:modify {
                id="ratio_height",
                text=label_ratio_height_text(new_export_size.height)
            }
        end
    }

    dialog:check {
        id = "selection_only",
        label = "Crop to selection:",
        text = selection_only_checkbox_text(selection_width, selection_height),
        enabled = true,
        selected = false,
        onclick = function()
            -- update the projected pixel ratios
            local new_export_size = calculate_export_size(sprite_width, sprite_height, dialog.data.percentage)
            if (dialog.data.selection_only) then
                new_export_size = calculate_export_size(selection_width, selection_height, dialog.data.percentage)
            end

            dialog:modify {
                id="ratio_width",
                text=label_ratio_width_text(new_export_size.width)
            }

            dialog:modify {
                id="ratio_height",
                text=label_ratio_height_text(new_export_size.height)
            }
        end
    }

    dialog:separator {
        id="ratio_display"
    }

    dialog:label {
        id="ratio_width",
        label="New Width:",
        text=tostring(sprite_width).."px"
    }

    dialog:label {
        id="ratio_height",
        label="New Height:",
        text=tostring(sprite_height).."px"
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
