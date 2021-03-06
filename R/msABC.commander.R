
msABC.commander<-function(model,use.alpha=use.alpha){
  
  # bind Ne, mig and Time priors
  size.pars<-rbind(model$flags$n,model$flags$en$size)
  mig.pars<-rbind(model$flags$m,model$flags$em$size)
  time.pars<-rbind(model$flags$ej,model$flags$en$time,model$flags$em$time)
  
  # sample Ne, div.time and mutation rate
  size.pars<-sample.w.cond(par.matrix=size.pars,cond.matrix=model$conds$size.matrix)
  time.pars<-sample.w.cond(par.matrix=time.pars,cond.matrix=model$conds$time.matrix)
  loci<-sample.pars(model$loci)
  
  # empty parameter vector
  parameters<-vector()
  # bind Ne and time sampled parameters
  parameters<-rbind(parameters,size.pars[,c(1,4)])
  parameters<-rbind(parameters,time.pars[,c(1,4)])
  
  # sample migrations if present and bind sampled parameters
  if(is.null(mig.pars)==F){
    mig.pars<-sample.w.cond(par.matrix=mig.pars,cond.matrix=model$conds$mig.matrix)
    #bind sampled migration parameters
    parameters<-rbind(parameters,mig.pars[,c(1,4)])
  }
  
  #### bind sampled mutation rate
  parameters<-rbind(parameters,loci[,c(1,4)])
  
  ####### End of parameter sampling #######################################
  #########################################################################
  
  ####### Generate ms string ##############################################
  ####### Convertion to coalescent scale #####################################
  
  # generate coalescent scalar. Arbitrary value 
  if(model$flags$n[1,6]=="runif") {Ne0<-min(as.numeric(model$flags$n[,4]))
  } else {Ne0<-mean(as.numeric(model$flags$n[,4]))}
  ms.scalar<-4*Ne0
  
  #### bind scaled theta per gene (4Ne0*m*pb)
  loci<-cbind(loci,ms.scalar*as.numeric(loci[,4])*as.numeric(loci[,2]))
  
  #### convertion of time to coalescent scale
  time.pars[,4:5]<-as.numeric(time.pars[,4])/ms.scalar
  
  
  size.pars.original<-size.pars
  mig.pars.original<-mig.pars
  
  commands<-list(NULL)
  for(u in 1:nrow(loci)){
  
      size.pars<-size.pars.original
      mig.pars<-mig.pars.original
      # rescale to inheritance scalar and transform size parameters to relative to Ne0
      size.pars[,4:5]<-as.numeric(size.pars[,4])*as.numeric(loci[u,3])
      size.pars[,4:5]<-as.numeric(size.pars[,4])/Ne0
      
      # rescale migration to inheritance scalar
      mig.pars[,4:5]<-as.numeric(mig.pars[,4])*as.numeric(loci[u,3])
      
      # empty string for ms flags
      string<-list()
      
      ################### size parameters ############################
      ################################################################
      ### 
      curr.Ne<-subset(size.pars, size.pars[,2]=="-n")
      ent<-subset(time.pars, time.pars[,2]=="-en")
      en<-subset(size.pars, size.pars[,2]=="-en")
      
      # generate Ne string
      if(nrow(curr.Ne)==1){
        string[[1]]<-paste(curr.Ne[2:4],collapse = " ")
      } else {
      l<-apply(curr.Ne[,c(2:4)],1,paste,collapse=" ")
      string[[1]]<-paste(l,collapse = " ")
      }
      # generate alpha string
      if(use.alpha==T){
        alpha<-NULL
        for(i in as.numeric(unique(en[,3]))){
          eg<-subset(size.pars, size.pars[,3]==i)[1:2,]
          eg<-rbind(eg,subset(ent, ent[,3]==i))
          alpha<-c(alpha,paste("-g",i,-(1/as.numeric(eg[3,4]))*log(as.numeric(eg[2,4])/as.numeric(eg[1,4]))))
        
        }
        string[[2]]<-paste(alpha, collapse=" ")
      }
      
      # generate ancestral Ne string   
      if(nrow(en)!=0){
        if(nrow(en)>1){
        n<-apply(cbind(ent[,c(2,4)],en[,3:4]),1,paste,collapse=" ")
        string[[3]]<-paste(n, collapse=" ")
        } else {string[[3]]<-paste(c(ent[c(2,4)],en[3:4]), collapse=" ")}
      }  
      
      ######### migration parameters #########################
      ####################################################
      ########
      
      if(is.null(mig.pars)==F){
        
        ###### transform current mig parameters
        curr.mig<-subset(mig.pars, mig.pars[,2]=="-m")
        for(i in 1:nrow(curr.mig)){
        curr.mig[i,3]<-strsplit(curr.mig[i,3]," ")[[1]][1]
        }
        curr.mig[,4]<-as.numeric(curr.mig[,4])/as.numeric(curr.Ne[match(curr.mig[,3],curr.Ne[,3]),4])
        curr.mig[,3]<-mig.pars[1:nrow(curr.mig),3]
        
        ###### generate current migration string
        m<-apply(curr.mig[,c(2:4)],1,paste,collapse=" ")
        string[[4]]<-paste(m, collapse=" ")
        
        ########################################
        ###### ancestral migration conversion ##
        emt<-subset(time.pars, time.pars[,2]=="-em")
        em<-subset(mig.pars, mig.pars[,2]=="-em")
        
        if(nrow(em)!=0){
          
          for(i in 1:nrow(emt)){
            emt[i,3]<-strsplit(emt[i,3]," ")[[1]][1]
            }
        
          if(nrow(en)==0){
            em[,4]<-as.numeric(em[,4])/as.numeric(curr.Ne[match(emt[,3],curr.Ne[,3]),4])
            } else {
              if(sum(as.numeric(em[,4]))>0){
                for(j in 1:nrow(em)){
                  x<-which(ent[,3]==emt[j,3])
                  if(length(x)==0){
                    em[j,4]<-as.numeric(em[i,4])/as.numeric(curr.Ne[match(emt[j,3],curr.Ne[,3]),4])  
                    } else {
                      y<-which(as.numeric(ent[x,4])<=as.numeric(emt[j,4]))
                      if(length(y)==0){
                        em[j,4]<-as.numeric(em[j,4])/as.numeric(curr.Ne[match(emt[j,3],curr.Ne[,3]),4])
                        }else{
                          y<-which(as.numeric(ent[x,4])==max(as.numeric(ent[x[y],4])))
                          em[j,4]<-as.numeric(em[j,4])/as.numeric(en[x[y],4])
                        }
                    }
                }
              }
            }
          ## generate ancestral migration string
          m<-apply(cbind(emt[,c(2,4)],em[,3:4]),1,paste,collapse=" ")
          string[[5]]<-paste(m, collapse=" ")
        }
      }
      
      ############### joint parameters ##################################
      ###############################################################
      ########
        
      ej<-subset(time.pars, time.pars[,2]=="-ej")
      if(nrow(ej)==1){
        string[[6]]<-paste(ej[c(2,4,3)], collapse=" ")
      }else{
        j<-apply(ej[,c(2,4,3)],1,paste,collapse=" ")
        string[[6]]<-paste(j, collapse=" ")}
      
      # paste all strings toguether
      string<-paste(unlist(string),collapse=" ")
      
      #################################### theta and structure ###########################
      ######### generate -t and -I part of the command
      
      y<-paste(sum(as.numeric(model$I[u,4:ncol(model$I)])),"1 -t",loci[u,7],paste(model$I[u,2:ncol(model$I)],collapse=" "),collapse=" ")
      commands[[u]]<-paste(y,string, collapse=" ")
      }
  #### attach sampled parameters
  commands[[nrow(loci)+1]]<-t(parameters)
  return(commands)
  }
