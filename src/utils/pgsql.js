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
        }
        donecnt = donecnt + 1;
      });
    });
    const intid = setInterval(() => {
      if (donecnt == qcnt) {
        clearInterval(intid);
      
        callback();
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

const getTimetable = ()=>{
    query("SELECT * from timetable",(err,result)=>{
        callback(result)    
    })
    
}
const getJoblog = ()=>{
    query("Select * from joblog limit 50",(err,result)=>{
        callback(result)
    })
   
}
const getLogs = (jobname,date)=>{
    query("Select * from logs where jobname='"+jobname+"' and date='"+date+"'",(err,result)=>{
        callback(result)
    })
}

module.exports = {
    query:query,
    multiquery:multiquery,
    init:init,
    getTimetable:getTimetable,
    getJoblog:getJoblog,
    getLogs:getLogs
}