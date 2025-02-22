function [OS, generatedBy] = getEnvInfo(opt)
  %
  % Gets information about the environment and operating system
  % to help generate data descriptors for the derivatives.
  %
  % USAGE::
  %
  %   [OS, generatedBy] = getEnvInfo()
  %
  % :returns: :OS: (structure) (dimension)
  %           :generatedBy: (structure) (dimension)
  %

  % (C) Copyright 2020 bidspm developers

  if nargin < 1
    opt.verbosity = 2;
    opt.dryRun = false;
  end

  [branch, commit] = getRepoInfo();

  generatedBy(1).name = 'bidspm';
  generatedBy(1).Version =  getVersion();
  generatedBy(1).Branch = branch;
  generatedBy(1).Commit = commit;
  generatedBy(1).Description = '';
  generatedBy(1).CodeURL = returnRepoURL();
  generatedBy(1).DOI = 'https://doi.org/10.5281/zenodo.3554331';

  runsOn = 'MATLAB';
  if isOctave
    runsOn = 'Octave';
  end

  OS.name = computer();

  OS = getOsNameAndVersion(OS);

  OS.platform.name = runsOn;
  OS.platform.version = version();

  [a, b] = spm('ver');
  OS.spmVersion = [a ' - ' b];

  if opt.dryRun
    return
  end

  [keys, vals] = getenvall('system');
  for i = 1:numel(keys)

    keyname = regexprep(keys{i}, '[^a-zA-Z_]', '_');
    keyname = regexprep(keyname, '^_*', '');
    if length(keyname) > 63
      keyname = keyname(1:63);
    end

    if ismember(keyname, {'_', ''})
      continue
    end

    OS.environmentVariables.(keyname) = vals{i};

  end

end

function OS = getOsNameAndVersion(OS)

  if ismember(OS.name, {'GLNXA64'})

    OS.name = 'unix';

    try
      [~, result] = system('lsb_release -d');
      tokens = regexp(result, 'Description:', 'split');
      OS.version = strtrim(tokens{2});
    catch
      [~, OS.version] = system('cat /proc/version');
    end

  elseif ismember(OS.name, {'MACI64'})

    [~, result] = system('sw_vers');
    tokens = regexp(result, newline, 'split');

    ProductName = regexp(tokens{1}, 'ProductName:', 'split');
    ProductVersion = regexp(tokens{2}, 'ProductVersion:', 'split');

    OS.name = strtrim(ProductName{2});
    OS.version = strtrim(ProductVersion{2});

  elseif ismember(OS.name, 'PCWIN64')

    [~, result] = system('ver');
    tokens = regexp(result, 'Version ', 'split');

    OS.name = 'Microsoft Windows';
    try
      OS.version = tokens{2}(1:end - 2);
    catch
      msg = sprintf(['Could not parse OS version %s.', ...
                     '\nPlease report here: %s'], ...
                    result, ...
                    'https://github.com/cpp-lln-lab/bidspm/issues');
      id = 'osParseError';
      logger('WARNING', msg, 'id', id);
      OS.version = ver;
    end

  end

end

function [keys, vals] = getenvall(method)
  % from
  % https://stackoverflow.com/questions/20004955/list-all-environment-variables-in-matlab
  if nargin < 1
    method = 'system';
  end
  method = validatestring(method, {'java', 'system'});

  switch method
    case 'java'
      map = java.lang.System.getenv();  % returns a Java map
      keys = cell(map.keySet.toArray());
      vals = cell(map.values.toArray());
    case 'system'
      if ispc()
        cmd = 'set';
      else
        cmd = 'env';
      end
      [~, out] = system(cmd);
      vars = regexp(strtrim(out), '^(.*)=(.*)$', ...
                    'tokens', 'lineanchors', 'dotexceptnewline');
      vars = vertcat(vars{:});
      keys = vars(:, 1);
      vals = vars(:, 2);
  end

  % Windows environment variables are case-insensitive
  if ispc()
    keys = upper(keys);
  end

  % sort alphabetically
  [keys, ord] = sort(keys);
  vals = vals(ord);
end
