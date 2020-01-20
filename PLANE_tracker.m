% Request user input from the command-line for application parameters
userInput = helperAdsbUserInput;

% Calculate ADS-B system parameters based on the user input
[adsbParam,sigSrc] = helperAdsbConfig(userInput);

% Create the data viewer object and configure based on user input
viewer = helperAdsbViewer('LogFileName', userInput.LogFilename, ...
    'SignalSourceType', userInput.SignalSourceType);
if userInput.LogData
  startDataLog(viewer);
end
if userInput.LaunchMap
  startMapUpdate(viewer);
end

% Create message parser object
msgParser = helperAdsbRxMsgParser(adsbParam);

% Start the viewer and initialize radio time
start(viewer)
radioTime = 0;

% Main loop
while radioTime < userInput.Duration


     if adsbParam.isSourceRadio
        if adsbParam.isSourcePlutoSDR
            [rcv,~,lostFlag] = sigSrc();
        else
            [rcv,~,lost] = sigSrc();
            lostFlag = logical(lost);
        end
    else
        rcv = sigSrc();
        lostFlag = false;
     end

  % Process physical layer information (Physical Layer)
  [pkt,pktCnt] = helperAdsbRxPhy(rcv, radioTime, adsbParam);

  % Parse message bits (Message Parser)
  [msg,msgCnt] = msgParser(pkt,pktCnt);

  % View results packet contents (Data Viewer)
  update(viewer, msg, msgCnt, lostFlag);

  % Update radio time
  radioTime = radioTime + adsbParam.FrameDuration;
end

% Stop the viewer and release the signal source
stop(viewer)
release(sigSrc)