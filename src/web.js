const express=require('express')
const log = require('./utils/log')
const hbs=require('hbs');
const pgsql = require('./utils/pgsql');
const path = require("path")

webserver=express()

webserver.set("view engine", "hbs"); // без этого hbs на express не работает
webserver.set("views", path.join(__dirname, "../templates/views")); // где hbs лежат
webserver.use(express.static(path.join(__dirname, "../public")));
hbs.registerPartials(path.join(__dirname, "../templates/partials"));

const port= 80;


webserver.get('/timetable',(req,res)=>{
    pgsql.getTimetable((result)=>{
        res.send({result})
    })
})
webserver.get('/joblog',(req,res)=>{
    pgsql.getJoblog((result)=>{
        res.send({result})
    })
})
webserver.get('/logs',(req,res)=>{
        pgsql.getLogs(req.jobname,req.date,(result)=>{
        res.send({result})
    })
})
webserver.get('*',(req,res)=>{
    res.render('jober')
})

const launch = (port) => {
  
    webserver.listen(port, () => {
      log.cls("Jober", "WEB Server");
      log.timestamp("WEB Server launched on port " + port);
    }).on('error',()=>{
      // console.log(error);
      port += 1;
      launch(port);
    });
  
};

if(process.argv[2] == "init"){
    pgsql.init();
}
if ((process.argv[2] == "start")) {
  launch(port);
}

