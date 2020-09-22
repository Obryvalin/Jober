const path = require("path")
const log = require("./log")
const {Pool} = require("pg");
const fs = require("fs")
const chalk = require("chalk")

const pgoptions = JSON.parse(fs.readFileSync("conf/pg.json").toString());
const { dropQueries, createQueries} = pgoptions;

pool = new Pool(pgoptions)


const query = (sql,callback) =>{
    // log.timestamp(sql);
    pool.query(sql, (err, res) => {
      if (err) {
        log.timestamp("PGSQL query error for request: "+chalk.greenBright(sql))
        log.timespamp(chalk.red(err));
      }
      if (!err) {
        if (callback){callback(undefined,res);}
      }
      
    });
  }


  const multiquery = (queries, callback) => {
    const qcnt = queries.length;
    var endedPool;
    if (qcnt == 0) {
      callback();
    }
    var donecnt = 0;
    
    queries.forEach((query) => {
      
      pool.query(query, (err, res) => {
        if (err) {
          log.timestamp(chalk.red(err))
          log.timestamp("Query was: "+query)
          logError(chalk.red(err));
        }
        donecnt = donecnt + 1;
      });
    });
    const intid = setInterval(() => {
      // log.timestamp(donecnt+"/"+qcnt)
      if (donecnt == qcnt) {
        clearInterval(intid);
      
        callback();
      }
      if (donecnt > qcnt){
        console.log("Multiquery error! Donecnt:"+donecnt+", qcnt:"+qcnt)
      }
      
    }, 50);
  };
  
const init = () => {
    
    multiquery(dropQueries,() => {
      log.timestamp("Tables droped!")
      multiquery(createQueries,()=>{
        log.timestamp("Tables created!")
        pool.end();
        log.timestamp("Init completed!")});
    });
  
    
  };

const getTimetable = (callback)=>{
    query("SELECT * from timetable",(err,result)=>{
        callback(result.rows)    
    })
    
}
const getJoblog = (callback)=>{
    query("Select * from joblog limit 50",(err,result)=>{
        callback(result.rows)
    })
   
}
const getLogs = (jobname,date,callback)=>{
    query("Select * from logs where jobname='"+jobname+"' and date='"+date+"'",(err,result)=>{
        callback(result.rows)
    })
}
const addJob = (reqdata,callback) =>{
    query("Insert into Timetable(weekday,starttime,process,jobname,filepath) values("+reqdata.weekday+","+reqdata.time+",'"+reqdata.process+"','"+reqdata.jobName+"','"+reqdata.path+"')",(err,res)=>{
      callback(err || res)
    })
}

module.exports = {
    query:query,
    multiquery:multiquery,
    init:init,
    getTimetable:getTimetable,
    getJoblog:getJoblog,
    getLogs:getLogs,
    addJob:addJob
}