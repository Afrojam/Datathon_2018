Kfilter = function(num,y,A,mu0,Sigma0,Phi,cQ,cR){
#
# NOTE: must give cholesky decomp: cQ=chol(Q), cR=chol(R)

	Q=t(cQ)%*%cQ
	R=t(cR)%*%cR

# y is num by q  (time=row series=col)
# A is a **list** of n+1 (the first one isn't used), q by p matrices
# R is q by q
# mu0 is p by 1
# Sigma0, Phi, Q are p by p
# NOTE to match index with time:
# i=1 => t=0,..., i=num+1 => t=num
	
	N=num+1
	nseries=ncol(as.matrix(y))
	yobs=matrix(0,N,nseries)
	yobs[2:N,]=y      # yobs is y with first row=zeros

  	# Initialize
	xp=vector("list",N)     # xp=x_t^{t-1}
	Pp=vector("list",N)     # Pp=P_t^{t-1}
	xf=vector("list",N)     # xf=x_t^t
	Pf=vector("list",N)     # Pf=x_t^t
	innov=vector("list",N)  # innovations
	sig=vector("list",N)    # innov var-cov matrix
	like=0                  # -log(likelihood)
	xf[[1]]=mu0
	Pf[[1]]=Sigma0
	for (i in 2:N){
 		xp[[i]]=Phi%*%xf[[i-1]]
		Pp[[i]]=Phi%*%Pf[[i-1]]%*%t(Phi)+Q
   		siginv=A[[i]]%*%Pp[[i]]%*%t(A[[i]])+R
 		sig[[i]]=(t(siginv)+siginv)/2     # make sure sig is symmetric
   		siginv=solve(sig[[i]])          # now siginv is sig[[i]]^{-1}
 		K=Pp[[i]]%*%t(A[[i]])%*%siginv
 		innov[[i]]=as.matrix(yobs[i,])-A[[i]]%*%xp[[i]]
 		xf[[i]]=xp[[i]]+K%*%innov[[i]]
 		Pf[[i]]=Pp[[i]]-K%*%A[[i]]%*%Pp[[i]]
 		like= like + log(det(sig[[i]])) + t(innov[[i]])%*%siginv%*%innov[[i]]
 	}
   	like=0.5*like
   	list(xp=xp,Pp=Pp,xf=xf,Pf=Pf,like=like,innov=innov,sig=sig,Kn=K)
}




Ksmooth = function(num,y,A,mu0,Sigma0,Phi,cQ,cR){
#
# Note: Q and R are given as Cholesky decomps
#       cQ=chol(Q), cR=chol(R)
#
 	kf=Kfilter(num,y,A,mu0,Sigma0,Phi,cQ,cR)
 	N=num+1
 	xs=vector("list",N)     # xs=x_t^n
 	Ps=vector("list",N)     # Ps=P_t^n
 	J=vector("list",N)      # J=J_t
 	xs[[N]]=kf$xf[[N]]
 	Ps[[N]]=kf$Pf[[N]]
 	for(k in N:2)  {
 		J[[k-1]]=(kf$Pf[[k-1]]%*%t(Phi))%*%solve(kf$Pp[[k]])
 		xs[[k-1]]=kf$xf[[k-1]]+J[[k-1]]%*%(xs[[k]]-kf$xp[[k]])
 		Ps[[k-1]]=kf$Pf[[k-1]]+J[[k-1]]%*%(Ps[[k]]-kf$Pp[[k]])%*%t(J[[k-1]])
	}
	list(xs=xs,Ps=Ps,J=J,xp=kf$xp,Pp=kf$Pp,xf=kf$xf,Pf=kf$Pf,like=kf$like,Kn=kf$K)
} 

EM = function(num,y,A,mu0,Sigma0,Phi,cQ,cR,max.iter,tol,fixed=c(0,0,0)){
#
# Note: Q and R are given as Cholesky decomps
#       cQ=chol(Q), cR=chol(R)
#
  	N=num+1
   	statedim=nrow(as.matrix(Phi))
   	obsdim=ncol(as.matrix(y))
   	yobs=matrix(0,N,obsdim)
   	yobs[2:N,]=y      # yobs is y with first row=zeros

   	cvg=1+tol
   	like=matrix(0,max.iter,1)
	for(iter in 1:max.iter){ 
  		ks=Ksmooth(num,y,A,mu0,Sigma0,Phi,cQ,cR)
  		like[iter]=ks$like
  		if(iter>1) cvg=abs(like[iter-1]-like[iter])
  		if(cvg<tol) break
		# Lag-One Covariance Smoothers 
  		Pcs=vector("list",N)     # Pcs=P_{t,t-1}^n
  		eye=diag(1,statedim)
  		Pcs[[N]]=(eye-ks$Kn%*%A[[N]])%*%Phi%*%ks$Pf[[N-1]]
   		for(k in N:3){
   			Pcs[[k-1]]=ks$Pf[[k-1]]%*%t(ks$J[[k-2]])+
             			ks$J[[k-1]]%*%(Pcs[[k]]-Phi%*%ks$Pf[[k-1]])%*%t(ks$J[[k-2]])
   		}
		# Estimation
  		S11=matrix(0,statedim,statedim)
  		S10=matrix(0,statedim,statedim)
	  	S00=matrix(0,statedim,statedim)
 	 	
		if (fixed[3]==0) R=matrix(0,obsdim,obsdim)
 		for(i in 2:N){
    			S11 = S11 + ks$xs[[i]]%*%t(ks$xs[[i]]) + ks$Ps[[i]]
    			S10 = S10 + ks$xs[[i]]%*%t(ks$xs[[i-1]]) + Pcs[[i]]
    			S00 = S00 + ks$xs[[i-1]]%*%t(ks$xs[[i-1]]) + ks$Ps[[i-1]]
    			if (fixed[3]==0) {
     				u = as.matrix(yobs[i,])-A[[i]]%*%ks$xs[[i]]
				R = R + u%*%t(u) + A[[i]]%*%ks$Ps[[i]]%*%t(A[[i]])
				}
  		}
  		if (fixed[1]==0) Phi=S10%*%solve(S00)
  		if (fixed[2]==0) {
			Q=(S11-S10%*%solve(S00)%*%t(S10))/num
  	 		Q=(t(Q)+Q)/2        # make sure symmetric
                  Q=diag(diag(Q)) #modificació a mida
  			cQ=chol(Q)
			}
  		if (fixed[3]==0){
			R=R/num
                  R=diag(diag(R)) #modificació a mida
  			cR=chol(R)

			}
  		mu0=ks$xs[[1]]
		# mu0=mu0              # uncomment this line to keep mu0 fixed
  		Sigma0=ks$Ps[[1]]
		# Sigma0=Sigma0        # uncomment this line to keep Sigma0 fixed
	}
	list(Phi=Phi,Q=Q,R=R,mu0=mu0,Sigma0=Sigma0,like=like[1:iter],niter=iter,cvg=cvg)
} 


EMmiss = function(num,nmiss,y,A,mu0,Sigma0,Phi,cQ,cR,fixed=c(0,0,0),max.iter,tol){
#
#  THIS CODE IS GOOD WHEN DATA AT TIME t ARE ALL OBSERVED OR ALL MISSING
#  AS IN THE JONES DATA EXAMPLE. FOR THE GENERAL CASE, SEE (6.90) on p. 354
#
#  nmiss = number of missing observations
#  Note: Q and R are given as Cholesky decomps
#        cQ=chol(Q)
#        R is diagonal, so cR=chol(R)=sqrt(R)

#
   N=num+1
   statedim=nrow(as.matrix(Phi))
   obsdim=ncol(as.matrix(y))
   yobs=matrix(0,N,obsdim)
   yobs[2:N,]=y      # yobs is y with first row=zeros
   cvg=1+tol
   like=matrix(0,max.iter,1)
   for(iter in 1:max.iter){ 
  	ks=Ksmooth(num,y,A,mu0,Sigma0,Phi,cQ,cR)
  	like[iter]=ks$like
  	if(iter>1) cvg=abs(like[iter-1]-like[iter])
  	if(cvg<tol) break
# Lag-One Covariance Smoothers 
  	Pcs=vector("list",N)     # Pcs=P_{t,t-1}^n
  	eye=diag(1,statedim)
  	Pcs[[N]]=(eye-ks$Kn%*%A[[N]])%*%Phi%*%ks$Pf[[N-1]]
   	for(k in N:3){
   		Pcs[[k-1]]=ks$Pf[[k-1]]%*%t(ks$J[[k-2]])+
             	ks$J[[k-1]]%*%(Pcs[[k]]-Phi%*%ks$Pf[[k-1]])%*%t(ks$J[[k-2]])
   	}
# Estimation
  	S11=matrix(0,statedim,statedim)
  	S10=matrix(0,statedim,statedim)
  	S00=matrix(0,statedim,statedim)
  
  	if (fixed[3]==0) newR=matrix(0,obsdim,obsdim)
  	for(i in 2:N){
    		S11 = S11 + ks$xs[[i]]%*%t(ks$xs[[i]]) + ks$Ps[[i]]
    		S10 = S10 + ks$xs[[i]]%*%t(ks$xs[[i-1]]) + Pcs[[i]]
    		S00 = S00 + ks$xs[[i-1]]%*%t(ks$xs[[i-1]]) + ks$Ps[[i-1]]
    		if (fixed[3]==0) {
     			u = as.matrix(yobs[i,])-A[[i]]%*%ks$xs[[i]]
    			newR = newR + u%*%t(u) + A[[i]]%*%ks$Ps[[i]]%*%t(A[[i]])  
    		}
  	}
  	if (fixed[1]==0) Phi=S10%*%solve(S00)
  	if (fixed[2]==0) {
  		Q=(S11-S10%*%solve(S00)%*%t(S10))/num
   		Q=(t(Q)+Q)/2        # make sure symmetric
  		cQ=chol(Q)
  	}
  	oldR=t(cR)%*%cR
  	if (fixed[3]==0){
  		oldR=t(cR)%*%cR
  		R=(newR + nmiss*oldR)/num
    		R=diag(diag(R), obsdim)        # R is diagonal
  		cR=sqrt(R)}
  	else{
  		R=oldR
  	}
  	mu0=ks$xs[[1]]
  	Sigma0=ks$Ps[[1]]
    	}
 	list(Phi=Phi,Q=Q,R=R,mu0=mu0,Sigma0=Sigma0,like=like[1:iter],niter=iter,cvg=cvg)
} 


SVfilter = function(num,y,phi0,phi1,sQ,alpha,sR0,mu1,sR1){
#
#  y is log(return^2)
#
#  
	# Initialize
	y=as.matrix(y)
	Q=sQ^2
	R0=sR0^2
	R1=sR1^2
	xf=0     	     # =h_0^0
	Pf=sQ^2/(1-phi1)     # =P_0^0
	Pf[Pf<0]=0           # make sure Pf not negative
	xp=matrix(0,num,1)   # =h_t^t-1
	Pp=matrix(0,num,1)   # =P_t^t-1
	pi1=.5    	     #initial mix probs
	pi0=.5
	fpi1=.5
	fpi0=.5
	like=0                  # -log(likelihood)
	
	for (i in 1:num){
 		xp[i]=phi1*xf+phi0
 		Pp[i]=phi1*Pf*phi1+Q
  		sig1=Pp[i]+R1     #innov var
  		sig0=Pp[i]+R0 
  		k1=Pp[i]/sig1
  		k0=Pp[i]/sig0
  		e1=y[i]-xp[i]-mu1-alpha
  		e0=y[i]-xp[i]-alpha
  
	 	den1= (1/sqrt(sig1))*exp(-.5*e1^2/sig1)
 		den0= (1/sqrt(sig0))*exp(-.5*e0^2/sig0)
 		denom=pi1*den1+pi0*den0
 		fpi1=pi1*den1/denom
 		fpi0=pi0*den0/denom

 		xf= xp[i]+ fpi1*k1*e1+fpi0*k0*e0
 		Pf=fpi1*(1-k1)*Pp[i]+ fpi0*(1-k0)*Pp[i]
 		like= like - 0.5*log(pi1*den1 + pi0*den0)
 	}
 	list(xp=xp,Pp=Pp,like=like)
}

