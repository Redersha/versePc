const l = require('./server/launch');
console.log(typeof l.launchGame, typeof l.buildLaunchArguments);
console.log(typeof l.doLaunch, typeof l.analyzeExitCode);
console.log(typeof l.preheatJvm, typeof l.applyPerformanceOptimizations);
console.log(typeof l.setGameLanguage, typeof l.applyWindowSettings);
