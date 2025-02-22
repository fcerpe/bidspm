function bugReport(opt, ME)
  %
  % Write a small bug report.
  %
  % USAGE::
  %
  %   bugReport(opt)
  %
  %

  % (C) Copyright 2022 bidspm developers

  opt.verbosity = 3;
  if nargin < 1
    opt.dryRun = false;
  end

  [OS, GeneratedBy] = getEnvInfo(opt);

  json.GeneratedBy = GeneratedBy;
  json.OS = OS;
  if nargin > 1
    json.ME = ME;
  end

  output_dir = pwd;
  if isfield(opt, 'dir') && isfield(opt.dir, 'output')
    output_dir = opt.dir.output;
  end
  output_dir = fullfile(output_dir, 'error_logs');
  spm_mkdir(output_dir);

  logger('WARNING', 'An error occurred');
  unfold(json);

  logFile = spm_file(fullfile(output_dir, sprintf('error_%s.log', timeStamp())), 'cpath');
  bids.util.jsonwrite(logFile, json);
  printToScreen(sprintf(['\nERROR LOG SAVED:\n\t%s\n', ...
                         'Use it when opening an issue:\n\t%s.\n\n'], ...
                        pathToPrint(logFile), ...
                        [returnRepoURL() '/issues/new/choose']), ...
                opt, ...
                'format', 'red');

end
