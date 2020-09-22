const fs = require("fs");
const chalk = require('chalk');
const dateformat = require("date-format")

const {logpath} = JSON.parse(fs.readFileSync('conf/log.json'))

if (!fs.existsSync(logpath)){fs.writeFileSync(logpath,"")}

function cls(processName, workerName) {
  console.clear();
  console.log("=====================");
  console.log("Process: " + chalk.bold.cyanBright (processName));
  console.log("Worker: " + chalk.bold.cyanBright(workerName));
  var date = dateformat('yy.MM.dd hh:mm:ss.SSS', new Date());
  console.log("Текущее время: " + date);
  console.log("=====================");
}

function timestamp(msg) {
  var date = dateformat('yy.MM.dd hh:mm:ss.SSS', new Date());
  console.log("[" + date + "] " + msg);
  fs.appendFile(logpath, "\n[" + date + "] " + msg.toString(),()=>{});
}

function clearlog() {
  fs.unlink(logpath, () =>{
    console.log(logpath + " deleted!");
  });
}

//console.log('log.js loaded');
module.exports = {
  timestamp: timestamp,
  clearlog: clearlog, 
  cls: cls 
};
