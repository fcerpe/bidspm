function matlabbatch = bidsRFX(action, opt)
  %
  % - smooths all contrast images created at the subject level
  %
  % OR
  %
  % - creates a mean structural image and mean mask over the sample
  %
  % OR
  %
  % - specifies and estimates the group level model,
  % - computes the group level contrasts.
  %
  % USAGE::
  %
  %  bidsRFX(action, opt)
  %
  % :param action: Action to be conducted: ``'smoothContrasts'`` or ``'RFX'`` or
  %                ``'meanAnatAndMask'``
  % :type action: string
  %
  % :param opt: structure or json filename containing the options. See
  %             ``checkOptions()`` and ``loadAndCheckOptions()``.
  % :type opt: structure
  %
  %
  % (C) Copyright 2020 CPP_SPM developers

  opt.pipeline.type = 'stats';

  description = 'group level GLM';

  opt.dir.output = opt.dir.stats;

  % To speed up group level as we do not need to index raw data ?
  [BIDS, opt] = setUpWorkflow(opt, description);

  checks(opt, action);

  matlabbatch = {};

  % TODO refactor
  % - extract function for contrast smoothing
  % - extract function for anat and mask computation
  % - merge rfx and ffx into a single "stats" workflow

  switch lower(action)

    case 'smoothcontrasts'

      % TODO split this in a different workflow

      matlabbatch = setBatchSmoothConImages(matlabbatch, opt);

      saveAndRunWorkflow(matlabbatch, ...
                         ['smooth_con_FWHM-', num2str(opt.fwhm.contrast), ...
                          '_task-', strjoin(opt.taskName, '')], ...
                         opt);

    case 'meananatandmask'

      % TODO need to rethink where to save the anat and mask
      % TODO need to smooth the anat
      % TODO create a masked version of the anat too

      opt.dir.output = fullfile(opt.dir.stats, 'derivatives', 'cpp_spm-groupStats');
      opt.dir.jobs = fullfile(opt.dir.output, 'jobs',  strjoin(opt.taskName, ''));

      matlabbatch = setBatchMeanAnatAndMask(matlabbatch, ...
                                            opt, ...
                                            opt.dir.output);
      saveAndRunWorkflow(matlabbatch, 'create_mean_struc_mask', opt);

      opt.pipeline.name = 'cpp_spm';
      opt.pipeline.type = 'groupStats';
      initBids(opt, 'description', description, 'force', false);

    case 'rfx'

      opt.dir.output = fullfile(opt.dir.stats, 'derivatives', 'cpp_spm-groupStats');
      opt.dir.jobs = fullfile(opt.dir.output, 'jobs',  strjoin(opt.taskName, ''));

      datasetNodes = opt.model.bm.get_nodes('Level', 'Dataset');

      for i = 1:numel(datasetNodes)

        [matlabbatch, contrastsList] = setBatchFactorialDesign(matlabbatch, ...
                                                               opt, ...
                                                               datasetNodes{i}.Name);

        matlabbatch = setBatchEstimateModel(matlabbatch, opt, datasetNodes{i}.Name, contrastsList);

        saveAndRunWorkflow(matlabbatch, 'group_level_model_specification_estimation', opt);

      end

      opt.pipeline.name = 'cpp_spm';
      opt.pipeline.type = 'groupStats';
      initBids(opt, 'description', description, 'force', false);

    case 'contrast'

      opt.dir.output = fullfile(opt.dir.stats, 'derivatives', 'cpp_spm-groupStats');
      opt.dir.jobs = fullfile(opt.dir.output, 'jobs',  strjoin(opt.taskName, ''));

      datasetNodes = opt.model.bm.get_nodes('Level', 'Dataset');

      for i = 1:numel(datasetNodes)

        % for average at the group level
        if opt.model.bm.get_design_matrix('Name', datasetNodes{i}.Name) == 1

          contrastsList = getDummyContrastsList(datasetNodes{i}.Name, opt.model.bm);

        end

        matlabbatch = setBatchGroupLevelContrasts(matlabbatch, opt, contrastsList);

        saveAndRunWorkflow(matlabbatch, 'contrasts_rfx', opt);

      end

  end

end

function checks(opt, action)

  if numel(opt.space) > 1
    disp(opt.space);
    msg = sprintf('GLMs can only be run in one space at a time.\n');
    errorHandling(mfilename(), 'tooManySpaces', msg, false, opt.verbosity);
  end

  allowedActions = {'smoothcontrasts', 'meananatandmask', 'rfx', 'contrast'};
  if ~ismember(lower(action), allowedActions)
    msg = sprintf('action must be: %s.\n%s was given.', createUnorderedList(allowedActions), ...
                  action);
    errorHandling(mfilename(), 'unknownAction', msg, false, opt.verbosity);
  end

end
