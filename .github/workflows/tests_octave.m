function tests_octave()
  %

  % (C) Copyright 2021 bidspm developers

  % Elapsed time is 284 seconds.

  more off;

  tic;

  cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));

  bidspm('action', 'dev');

  bidspm('action', 'run_tests');

  toc;

end
