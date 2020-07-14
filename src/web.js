const express=require('express')
const log = require('./log')
const hbs=require('hbs');
const pgsql = require('../../FBR_FNS/src/utils/pgsql');

webserver=express()

webserver.set("view engine", "hbs"); // без этого hbs на express не работает
webserver.set("views", path.join(__dirname, "../templates/views")); // где hbs лежат
webserver.use(express.static(path.join(__dirname, "../public")));
hbs.registerPartials(path.join(__dirname, "../templates/partials"));

const port= 80;


webserver.get('/timetable',(req,res)=>{
    pgsql.getTimetable((result)=>{
        res.render('gettimetable',{result})
    })
})
webserver.get('/joblog',(req,res)=>{
    pgsql.getJoblog((result)=>{
        res.render('getjoblog',{result})
    })
})
webserver.get('*',(req,res)=>{
    res.render('jober')
})

const launch = (port) => {
  
    webserver.listen(port, () => {
      log.cls(processtext, "WEB Server");
      log.timestamp("WEB Server launched on port " + port);
    }).on('error',()=>{
      // console.log(error);
      port += 1;
      launch(port);
    });
  
};
launch(port);
