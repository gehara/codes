
switch.main.menu<-function(){
  .e$YES<-c("Y","y","yes","YES","Yes")
  .e$NO<-c("N","n","No","NO","no")
  
  switch(letter,
         
         A = {remove.all.par()
              join.par()
              cur.Ne.par()
              sys.call(which = 0)
              main.menu()},
         
         B = {join.par()
              cur.Ne.par()
              sys.call(which = 0)
              main.menu()},
         
         C = {.e$mig.presence<-readline("Migration among populations (YES or NO)?: ")
              if(.e$mig.presence %in% .e$YES){
                mig.par()
                } else if (.e$mig.presence %in% .e$NO){
                  options(warn=-1)
                  rm(m,em,envir=.e)
                  options(warn=0)
                }
         sys.call(which = 0)
                main.menu()},
         
         
         D = {hist.demog<-readline("Ne change throgh time (YES or NO?): ")
         if (hist.demog %in% .e$YES){
           anc.Ne.par()
           } else if (hist.demog %in% .e$NO){
            options(warn=-1)
            rm(en,envir=.e)
            options(warn=0)
           }
         sys.call(which = 0)
         main.menu()},
         
         E = {sys.call(which = 0)
              demog.menu()},
         
        "F" = {if(exists("m",envir=.e)){
              }else{
              .e$mig.presence<-readline("Migration among populations (YES or NO)?: " )
              if(.e$mig.presence=="NO"){ 
                sys.call(which = 0)
                main.menu()
                } else {mig.par()}
              }
          sys.call(which = 0)
              mig.menu()},
         
         G = {time.menu()},
         
         H = {condition.matrix()
           sys.call(which = 0)
              condition.menu()},
        
        I = {loci.par()
          samples.par()
          sys.call(which = 0)
          gene.menu()},
                
         Q={if(exists("size.matrix",envir=.e)){
         } else {condition.matrix()}
           if(exists("m",envir=.e) & exists("mig.matrix",envir=.e)==F){
             condition.matrix()
           }
           get.model()}
           
  )}

