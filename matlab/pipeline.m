wasserfall = RealtimeWasserfall();

while true
    line = wasserfall.readMetadata();
    disp(line);
end