function main(ver)
    print("Schooner setting limits version: " .. ver)
    local ret, msg = pcall(DataReporting.limitsVersion, ver)
    if not ret then
        local failureReason = 'Check device.log for details.'
        if msg:find('Version info has already been submitted') then
            failureReason =
            'Station code sets limits version while Schooner ' ..
            'generates non-empty limits version. If station ' ..
            'provides limits table version in LimitTableVersion.txt, ' ..
            'or have conditional limits, or use limit version override function, ' ..
            'please do not set limits version in test coverage.'
            print(msg)
            print('Schooner failed to set limits version. Reason: ' ..
                  failureReason)
        else
            print('Schooner failed to set limits version. ' .. msg)
        end

        DataReporting.submitRecord(false, 'Schooner', 'SetLimitsVersion',
                                   'Failure', failureReason)
    end
end
