function derivatives = getHRFderivatives(modelFile, nodeType)
  %
  % returns the HRF derivatives of a node of a BIDS statistical model
  %
  % (C) Copyright 2021 CPP_SPM developers

  derivatives =  [0 0];

  if isempty(modelFile)
    return
  end
  if nargin < 2 || isempty(nodeType)
    nodeType = 'run';
  end

  bm = bids.Model('file', modelFile);
  node = bm.get_nodes('Level', nodeType);

  if numel(node) > 1
    msg = sprintf('More than one node %s in BIDS model file\n%s', ...
                  nodeType, modelFile);
    errorHandling(mfilename(), 'moreThanOneModelNode', msg, false, true);
  end

  if iscell(node)
    node =  node{1};
  end

  HRFderivatives = '';
  try
    HRFderivatives = node.Model.Software.SPM.HRFderivatives;
  catch
    msg = sprintf('No HRF derivatives mentioned for node %s in BIDS model file: %s', ...
                  nodeType, modelFile);
    errorHandling(mfilename(), 'noHRFderivatives', msg, true, true);
  end

  if isempty(HRFderivatives) || strcmpi(HRFderivatives, 'none')
    return
  elseif strcmpi(HRFderivatives, 'temporal')
    derivatives =  [1 0];
  else
    derivatives =  [1 1];
  end

end
