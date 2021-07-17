const GulpClient = require('gulp');
const concat = require('gulp-concat');

GulpClient.task('build', function() {
  const pwd = __dirname;
  const safe_pwd = pwd.replace('[', '\\[').replace(']', '\\]');

  const recipe = [
    safe_pwd + '/app/src/app_start.js',
    safe_pwd + '/app/src/helpers/sort_helpers.js',
    safe_pwd + '/app/src/controllers/*',
    safe_pwd + '/app/src/app_stop.js'
  ];

  return GulpClient.src(recipe, { strict: true, sourcemaps: true })
    .pipe(concat('application.js'))
    .pipe(GulpClient.dest('./assets/script/'));
});
