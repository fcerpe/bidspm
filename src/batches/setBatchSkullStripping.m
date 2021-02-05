% (C) Copyright 2020 CPP BIDS SPM-pipeline developers

function matlabbatch = setBatchSkullStripping(matlabbatch, BIDS, opt, subID)
  %
  % Creates a batch to compute a brain mask based on the tissue probability maps
  % from the segmentation.
  %
  % USAGE::
  %
  %   matlabbatch = setBatchSkullStripping(matlabbatch, BIDS, opt, subID)
  %
  % :param matlabbatch: list of SPM batches
  % :type matlabbatch: structure
  % :param BIDS: BIDS layout returned by ``getData``.
  % :type BIDS: structure
  % :param opt: structure or json filename containing the options. See
  %             ``checkOptions()`` and ``loadAndCheckOptions()``.
  % :type opt: structure
  % :param subID: subject ID
  % :type subID: string
  %
  % :returns: - :matlabbatch: (structure) The matlabbatch ready to run the spm job
  %
  % This function will get its inputs from the segmentation batch by reading
  % the dependency from ``opt.orderBatches.segment``. If this field is not specified it will
  % try to get the results from the segmentation by relying on the ``anat``
  % image returned by ``getAnatFilename``.
  %
  % The threshold for inclusion in the mask can be set by::
  %
  %   opt.skullstrip.threshold (default = 0.75)
  %
  % Any voxel with p(grayMatter) +  p(whiteMatter) + p(CSF) > threshold
  % will be included in the skull stripping mask.
  %

  printBatchName('skull stripping');

  
  [anatImage, anatDataDir] = getAnatFilename(BIDS, subID, opt);
  output = ['m' strrep(anatImage, '.nii', '_skullstripped.nii')];
  dataDir = anatDataDir;
  maskOutput = ['m' strrep(anatImage, '.nii', '_mask.nii')];
  
  % best way would be in the dependencies of SPM, get the folder and file
  % name and use those to save the output
  
  % if the input image is mean func image instead of anatomical
  if opt.skullStripMeanImg == 1
      [meanImage, meanFuncDir] = getMeanFuncFilename(BIDS, subID, opt);
      
      % atm getMeanFunc only gets the native space mean func
      % adding the option to also get the mean MNI image
      if strcmp(opt.space, 'MNI')
        meanImage = ['w', meanImage];
      end
  
      %name the output accordingto the input image
      output = ['m' strrep(meanImage, '.nii', '_skullstripped.nii')];
      maskOutput = ['m' strrep(meanImage, '.nii', '_mask.nii')];
      
      %save things where the input image is
      dataDir = meanFuncDir;
  end
  
  expression = sprintf('i1.*((i2+i3+i4)>%f)', opt.skullstrip.threshold);

  % if this is part of a pipeline we get the segmentation dependency to get
  % the input from.
  % Otherwise the files to process are stored in a cell
  if isfield(opt, 'orderBatches') && isfield(opt.orderBatches, 'segment')

    input(1) = ...
        cfg_dep( ...
                'Segment: Bias Corrected (1)', ...
                substruct( ...
                          '.', 'val', '{}', {opt.orderBatches.segment}, ...
                          '.', 'val', '{}', {1}, ...
                          '.', 'val', '{}', {1}), ...
                substruct( ...
                          '.', 'channel', '()', {1}, ...
                          '.', 'biascorr', '()', {':'}));

    input(2) = ...
        cfg_dep( ...
                'Segment: c1 Images', ...
                substruct( ...
                          '.', 'val', '{}', {opt.orderBatches.segment}, ...
                          '.', 'val', '{}', {1}, ...
                          '.', 'val', '{}', {1}), ...
                substruct( ...
                          '.', 'tiss', '()', {1}, ...
                          '.', 'c', '()', {':'}));

    input(3) = ...
        cfg_dep( ...
                'Segment: c2 Images', ...
                substruct( ...
                          '.', 'val', '{}', {opt.orderBatches.segment}, ...
                          '.', 'val', '{}', {1}, ...
                          '.', 'val', '{}', {1}), ...
                substruct( ...
                          '.', 'tiss', '()', {2}, ...
                          '.', 'c', '()', {':'}));

    input(4) = ...
        cfg_dep( ...
                'Segment: c3 Images', ...
                substruct( ...
                          '.', 'val', '{}', {opt.orderBatches.segment}, ...
                          '.', 'val', '{}', {1}, ...
                          '.', 'val', '{}', {1}), ...
                substruct( ...
                          '.', 'tiss', '()', {3}, ...
                          '.', 'c', '()', {':'}));

  else

    % bias corrected image
    biasCorrectedAnatImage = validationInputFile(anatDataDir, anatImage, 'm');
    % get the tissue probability maps in native space for that subject
    TPMs = validationInputFile(anatDataDir, anatImage, 'c[123]');

    input{1} = biasCorrectedAnatImage;
    % grey matter
    input{2} = TPMs(1, :);
    % white matter
    input{3} = TPMs(2, :);
    % csf
    input{4} = TPMs(3, :);

  end

  matlabbatch = setBatchImageCalculation(matlabbatch, input, output, dataDir, expression);

  %% Add a batch to output the mask
  matlabbatch{end + 1} = matlabbatch{end};
  matlabbatch{end}.spm.util.imcalc.expression = sprintf( ...
                                                        '(i2+i3+i4)>%f', ...
                                                        opt.skullstrip.threshold);
  matlabbatch{end}.spm.util.imcalc.output = maskOutput;

end
