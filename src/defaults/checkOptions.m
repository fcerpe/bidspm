function opt = checkOptions(opt)
  %
  % Check the option inputs and add any missing field with some defaults
  %
  % Then it will search the derivatives directory for any zipped ``*.gz`` image
  % and uncompress the files for the task of interest.
  %
  % USAGE::
  %
  %   opt = checkOptions(opt)
  %
  % :param opt: structure or json filename containing the options.
  % :type opt: structure
  %
  % :returns:
  %
  % - :opt: the option structure with missing values filled in by the defaults.
  %
  % IMPORTANT OPTIONS (with their defaults):
  %
  %     - ``opt.taskName``
  %     - ``opt.dir``: EXPLAIN
  %     - ``opt.groups = {''}`` - group of subjects to analyze
  %     - ``opt.subjects = {[]}`` - suject to run in each group
  %         space where we conduct the analysis
  %         are located. See ``setDerivativesDir()`` for more information.
  %     - ``opt.space = {'individual', 'MNI'}`` - Space where we conduct the analysis
  %     - ``opt.realign.useUnwarp = true``
  %     - ``opt.useFieldmaps = true`` - when set to ``true`` the
  %         preprocessing pipeline will look for the voxel displacement maps (created by
  %     ``bidsCreateVDM()``) and will use them for realign and unwarp.
  %     - ``opt.model.file = ''`` - path to the BIDS model file that contains the
  %         model to speficy and the contrasts to compute.
  %     - ``opt.fwhm.func = 6`` - FWHM to apply to the preprocessed functional images.
  %     - ``opt.fwhm.contrast = 6`` - FWHM to apply to the contrast images before bringing
  %         them at the group level.
  %     - ``opt.query`` - a structure used to specify other options to only run analysis on
  %         certain files. ``struct('dir', 'AP', 'acq' '3p00mm')``. See ``bids.query``
  %         to see how to specify.
  %
  % OTHER OPTIONS (with their defaults):
  %
  %     - ``opt.verbosity = 1;`` - Set it to ``0`` if you want to see less output on the prompt.
  %     - ``opt.dryRun = false`` - Set it to ``true`` in case you don't want to run the analysis.
  %     - ``opt.pipeline.type = 'preproc'`` - Switch it to ``stats`` when running GLMs.
  %     - ``opt.pipeline.name = 'cpp_spm'``
  %     - ``opt.zeropad = 2`` - number of zeros used for padding subject numbers, in case
  %         subjects should be fetched by their number ``1`` and not their label ``O1'``.
  %     - ``opt.anatReference.type = 'T1w'`` -  type of the anatomical reference
  %     - ``opt.anatReference.session = ''`` - session label of the anatomical reference
  %     - ``opt.skullstrip.threshold = 0.75`` - Threshold used for the skull stripping.
  %         Any voxel with ``p(grayMatter) +  p(whiteMatter) + p(CSF) > threshold``
  %         will be included in the mask.
  %     - ``opt.funcVoxelDims = []`` - Voxel dimensions to use for resampling of functional data
  %         at normalization.
  %     - ``opt.stc.skip = false`` - boolean flag to skip slice time correction or not.
  %     - ``opt.stc.referenceSlice = []`` - reference slice for the slice timing correction.
  %         If left emtpy the mid-volume acquisition time point will be selected at run time.
  %     - ``opt.stc.sliceOrder = []`` - To be used if SPM can't extract slice info. NOT RECOMMENDED,
  %         if you know the order in which slices were acquired, you should be able to recompute
  %         slice timing and add it to the json files in your BIDS data set.
  %     -  ``opt.glm.roibased.do``
  %     -  ``opt.glm.QA.do = true`` - If set to ``true`` the residual images of a
  %         GLM at the subject levels will be used to estimate if there is any remaining structure
  %         in the GLM residuals (the power spectra are not flat) that could indicate
  %         the subject level results are likely confounded (see
  %         ``plot_power_spectra_of_GLM_residuals`` and `Accurate autocorrelation modeling
  %         substantially improves fMRI reliability
  %         <https://www.nature.com/articles/s41467-019-09230-w.pdf>`_ for more info.
  %
  %
  %
  % (C) Copyright 2019 CPP_SPM developers

  fieldsToSet = setDefaultOption();
  opt = setFields(opt, fieldsToSet);

  %  Options for toolboxes
  global ALI_TOOLBOX_PRESENT

  checkToolbox('ALI');
  if ALI_TOOLBOX_PRESENT
    opt = setFields(opt, ALI_my_defaults());
  end

  opt = setFields(opt, rsHRF_my_defaults());

  checkFields(opt);

  if any(strcmp(opt.pipeline.name, {'cpp_spm-stats', 'cpp_spm-preproc'}))
    opt.pipeline.name = 'cpp_spm';
  end

  if ~iscell(opt.query.modality)
    tmp = opt.query.modality;
    opt.query = rmfield(opt.query, 'modality');
    opt.query.modality{1} = tmp;
  end

  if ~iscell(opt.space)
    opt.space = {opt.space};
  end

  opt = orderfields(opt);

  opt = setDirectories(opt);

end

function fieldsToSet = setDefaultOption()

  % this defines the missing fields

  fieldsToSet.verbosity = 1;
  fieldsToSet.dryRun = false;

  fieldsToSet.pipeline.type = 'preproc';
  fieldsToSet.pipeline.name = 'cpp_spm';

  fieldsToSet.useBidsSchema = false;

  fieldsToSet.fwhm.func = 6;
  fieldsToSet.fwhm.contrast = 6;

  fieldsToSet.dir = struct('input', '', ...
                           'output', '', ...
                           'derivatives', '', ...
                           'raw', '', ...
                           'preproc', '', ...
                           'stats', '', ...
                           'jobs', '');

  fieldsToSet.groups = {''};
  fieldsToSet.subjects = {[]};
  fieldsToSet.zeropad = 2;

  fieldsToSet.query.modality = {'anat', 'func'};

  fieldsToSet.anatReference.type = 'T1w';
  fieldsToSet.anatReference.session = '';

  %% Options for slice time correction
  % all in seconds
  fieldsToSet.stc.referenceSlice = [];
  fieldsToSet.stc.sliceOrder = [];
  fieldsToSet.stc.skip = false;

  %% Options for realign
  fieldsToSet.realign.useUnwarp = true;
  fieldsToSet.useFieldmaps = true;

  %% Options for segmentation
  fieldsToSet.skullstrip.threshold = 0.75;
  fieldsToSet.skullstrip.mean = false;

  %% Options for normalize
  fieldsToSet.space = {'individual', 'MNI'};
  fieldsToSet.funcVoxelDims = [];

  %% Options for model specification and results
  fieldsToSet.model.file = '';
  fieldsToSet.model.hrfDerivatives = [0 0];
  fieldsToSet.contrastList = {};

  fieldsToSet.glm.QA.do = true;
  fieldsToSet.glm.roibased.do = false;

  % specify the results to compute
  fieldsToSet.result.Steps = returnDefaultResultsStructure();

  fieldsToSet.parallelize.do = false;
  fieldsToSet.parallelize.nbWorkers = 3;
  fieldsToSet.parallelize.killOnExit = false;

end

function checkFields(opt)

  if isfield(opt, 'taskName') && isempty(opt.taskName)

    msg = 'You may need to provide the name of the task to analyze.';
    errorHandling(mfilename(), 'noTask', msg, true, opt.verbosity);

  end

  if ~all(cellfun(@ischar, opt.groups))

    msg = 'All group names should be string.';
    errorHandling(mfilename(), 'groupNotString', msg, false, opt.verbosity);

  end

  if ~ischar(opt.anatReference.session)

    msg = 'The session label should be string.';
    errorHandling(mfilename(), 'sessionNotString', msg, false, opt.verbosity);

  end

  if ~isempty (opt.stc.referenceSlice) && length(opt.stc.referenceSlice) > 1

    msg = sprintf( ...
                  ['options.stc.referenceSlice should be a scalar.' ...
                   '\nCurrent value is: %d'], ...
                  options.stc.referenceSlice);
    errorHandling(mfilename(), 'refSliceNotScalar', msg, false, opt.verbosity);

  end

  if ~isempty (opt.funcVoxelDims) && length(opt.funcVoxelDims) ~= 3

    msg = sprintf( ...
                  ['opt.funcVoxelDims should be a vector of length 3. '...
                   '\nCurrent value is: %d'], ...
                  opt.funcVoxelDims);
    errorHandling(mfilename(), 'voxDim', msg, false, opt.verbosity);

  end

end
