local interactiveViewHelper = {}

function interactiveViewHelper.showGroupViewMessage(InteractiveView, message, messageColor)
    local groupIndex = Group.index - 1
    InteractiveView.showGroupView(groupIndex, {
        ["message"] = message,
        ["messageColor"] = messageColor or "blue",
        ["messageFont"] = 18,
        ["messageAlignment"] = 0
    })
end

function interactiveViewHelper.showView(InteractiveView, slotNum, message, messageColor, title, button)
    InteractiveView.showView(slotNum, {
        ["title"] = title,
        ["message"] = message,
        ["messageColor"] = messageColor or "red",
        ["messageFont"] = 16,
        ["button"] = button or {"OK"}
    })
end

-- groupViewNonBlockingUIMode = 0 :UI ok button disable, should use with interactiveView.dismissGroupView
-- groupViewNonBlockingUIMode = 1 or groupViewNonBlockingUIMode = nil: click ok button will output sn/slot table
function interactiveViewHelper.showScanBarcodeView(interactiveView, slotNum, title, input, length, groupViewNonBlockingUIMode)
    local output = interactiveView.showView(slotNum, {
        ["title"] = title,
        ["input"] = input,
        ["length"] = length
    }, groupViewNonBlockingUIMode)

    return output
end


-- [Usage] Device level : Blocks current device testing until the correct password is entered
function interactiveViewHelper.showLockView(interactiveView, slotNum)
    return interactiveView.showLockView(slotNum)
end

return interactiveViewHelper
