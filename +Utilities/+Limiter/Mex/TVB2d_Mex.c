#include "Limiter.h"

#define TOTALERR 1e-12

real TVB_minmod(real a1, real a2, real dx, real factor);

/**
 * @brief
 * Use minmod function to limit the gradient and get the linear 
 * limited result.
 * 
 * Usages:
 *		shape = mesh.Shape;
 * 		hlim  = TVB2d_Mex...
 *			(h, mesh.J, mesh.sJ, shape.M, shape.Fmask, mesh.EToE, mesh.Mes, mesh.x, mesh.y, factor)
 */
void mexFunction (int nlhs, mxArray *plhs[], 
	int nrhs, const mxArray *prhs[]){

	/* check input & output */
	if (nrhs != 10)
		mexErrMsgTxt("Wrong number of input arguments.");
	if (nlhs != 1)
		mexErrMsgTxt("Wrong number of output arguments");

	/* get inputs */
	real *h    = mxGetPr(prhs[0]);
	real *J    = mxGetPr(prhs[1]);
	real *sJ   = mxGetPr(prhs[2]);
	real *M    = mxGetPr(prhs[3]);
	real *Fmask= mxGetPr(prhs[4]);
	real *EToE = mxGetPr(prhs[5]);
	real *Mes  = mxGetPr(prhs[6]);
	real *x    = mxGetPr(prhs[7]);
	real *y    = mxGetPr(prhs[8]);
	real *factor = mxGetPr(prhs[9]);

	/* get dimensions */
	size_t Np, K;
	Np = mxGetM(prhs[0]); 
	K  = mxGetN(prhs[0]);
	size_t Nfaces,Nfp;
	Nfaces = mxGetM(prhs[4]);
	Nfp    = mxGetN(prhs[4]);

	/* allocation of output */
	plhs[0] = mxCreateDoubleMatrix((mwSize)Np, (mwSize)K, mxREAL);
	real *hlim = mxGetPr(plhs[0]);

	/* cell averages */
	real *hmean = (real*) malloc(sizeof(real)*K );
	real *area  = (real*) malloc(sizeof(real)*K );
	real *xmean = (real*) malloc(sizeof(real)*K );
	real *ymean = (real*) malloc(sizeof(real)*K );
	//elemental integral coefficient
	real *w     = (real*) malloc(sizeof(real)*Np); 
	real *ws    = (real*) malloc(sizeof(real)*Nfp); 

	/* volume/interface integral coefficient */
	int i,j,k,sk,sp,f,f1,f2,fnp;
	for(i=0;i<Np;i++){
		w[i] = 0.0;
		for(j=0;j<Np;j++){
			w[i] += M[i*Np + j];
		}
	}

	for(i=0;i<Nfp;i++){
		ws[i] = 0.0;
		for(j=0;j<Np;j++){
			ws[i] += Mes[i*Np + j];
		}
	}
	// calculate volume mean value
	for(k=0;k<K;k++){
		area [k] = 0.0;
		hmean[k] = 0.0;
		xmean[k] = 0.0;
		ymean[k] = 0.0;
		for(i=0;i<Np;i++){
			sk = (k*Np + i);
			hmean[k] += w[i]*J[sk]*h[sk];
			area [k] += w[i]*J[sk];
			xmean[k] += w[i]*J[sk]*x[sk];
			ymean[k] += w[i]*J[sk]*y[sk];
		}
		hmean[k] /= area[k];
		xmean[k] /= area[k];
		ymean[k] /= area[k];
	}

	real *neigh_mean = (real*) malloc(sizeof(real)*Nfaces );
	real *neigh_xc   = (real*) malloc(sizeof(real)*Nfaces );
	real *neigh_yc   = (real*) malloc(sizeof(real)*Nfaces );
	real *neigh_xf   = (real*) malloc(sizeof(real)*Nfaces );
	real *neigh_yf   = (real*) malloc(sizeof(real)*Nfaces );
	real *face_mean  = (real*) malloc(sizeof(real)*Nfaces );
	real *delta 	 = (real*) malloc(sizeof(real)*Nfaces );
	
	real alpha[2], a[4], df[2], v = 1.5;

	for(k=0;k<K;k++){
		real xc = xmean[k];
		real yc = ymean[k];
		
		/* calculate average on face */
		for(f=0;f<Nfaces;f++){
			face_mean[f] =0.0;
			neigh_xf[f] =0.0;
			neigh_yf[f] =0.0;
			real face_len = 0.0;

			// for(fnp=0;fnp<Nfp;fnp++){
			// 	sk = (k*Nfaces*Nfp + f*Nfp + fnp);
			//   	sp = k*Np + (int) (Fmask[f + fnp*Nfaces] - 1);
			// 	face_mean[f] += ws[fnp]*sJ[sk]*h[sp];
			// 	neigh_xf[f]  += ws[fnp]*sJ[sk]*x[sp];
			// 	neigh_yf[f]  += ws[fnp]*sJ[sk]*y[sp];
			// 	face_len 	 += ws[fnp]*sJ[sk];
			// }
			FaceMean(Nfaces, Nfp, h+k*Np, ws, sJ+k*Nfaces*Nfp+f*Nfp, Fmask+f,
				face_mean+f, &face_len);
			FaceMean(Nfaces, Nfp, x+k*Np, ws, sJ+k*Nfaces*Nfp+f*Nfp, Fmask+f,
				neigh_xf+f, &face_len);
			FaceMean(Nfaces, Nfp, y+k*Np, ws, sJ+k*Nfaces*Nfp+f*Nfp, Fmask+f,
				neigh_xf+f, &face_len);

			// face_mean[f] /= face_len;
			// neigh_xf[f]  /= face_len;
			// neigh_yf[f]  /= face_len;

			// averages of adjacent elements
			int e1 = (int)EToE[k+K*f] - 1;
			if(e1 == k){ // for boundary
				neigh_mean[f] = face_mean[f];
				neigh_xc[f] = neigh_xf[f];
				neigh_yc[f] = neigh_yf[f];
			}else{
				neigh_mean[f] = hmean[e1];
				neigh_xc[f] = xmean[e1];
				neigh_yc[f] = ymean[e1];
			}
		}

		
		for(f1=0;f1<Nfaces;f1++){
			/* find best other face */
			real max_alpha = -1.0;
			int  best_face = -1;
			real beat_alpha[2];

			// dxc[0] = neigh_xc[f1] - xc;
			// dyc[0] = neigh_yc[f1] - yc;
			// dxf    = neigh_xf[f1] - xc;
			// dyf    = neigh_yf[f1] - yc;
			a[0]  = neigh_xc[f1] - xc;
			a[2]  = neigh_yc[f1] - yc;
			df[0] = neigh_xf[f1] - xc;
			df[1] = neigh_yf[f1] - yc;

			for(f2=0;f2<Nfaces;f2++){
				if(f1==f2)
					continue;

				/* calculate of alpha */
				// dxc[1] = neigh_xc[f2] - xc;
				// dyc[1] = neigh_yc[f2] - yc;
				a[1] = neigh_xc[f2] - xc;
				a[3] = neigh_yc[f2] - yc;

				MatrixSolver2(a, df, alpha);

				// real det = dxc[0]*dyc[1] - dxc[1]*dyc[0];

				// alpha[0] = (dxf*dyc[1] - dyf*dxc[1])/det;
				// alpha[1] = (-dxf*dyc[0]+ dyf*dxc[0])/det;

				real alpha_det = sqrt(alpha[0]*alpha[0] + alpha[1]*alpha[1]);
				if ((alpha[0] > -TOTALERR) & (alpha[1] > -TOTALERR) & alpha[0]/alpha_det > max_alpha ){
					best_face = f2;
					max_alpha = alpha[0]/alpha_det;
					beat_alpha[0] = alpha[0];
					beat_alpha[1] = alpha[1];
				}
			}

			real dhc, dhf, len;

			dhc    = alpha[0]*(neigh_mean[f1] - hmean[k]) + alpha[1]*(neigh_mean[best_face] - hmean[k]);
			dhf    = face_mean[f1] - hmean[k];
			len    = sqrt( (neigh_xc[f1]-xc)*(neigh_xc[f1]-xc)+(neigh_yc[f1]-yc)*(neigh_yc[f1]-yc) );

			delta[f1] = TVB_minmod(dhf, dhc, len, *factor);

		}
		/* correct the average to sum to 0.0 */
		real sum = 0.0;
		for(f=0;f<Nfaces;f++){
			sum += delta[f];	
		}

		if( abs(sum)>TOTALERR ){
			real pos = 0.0;
			real neg = 0.0;

			for(f=0;f<Nfaces;f++){
				pos += max( delta[f], 0.0);
				neg += max(-delta[f], 0.0);
			}

			for(f=0;f<Nfaces;f++){
				delta[f] = min(1.0, neg/pos)*max(delta[f], 0.0) - min(1.0, pos/neg)*max(-delta[f], 0.0);
			}
		}

		/* reconstruct the cell value */
		real qpx = 0.0;
        real qpy = 0.0;

        for (f = 0; f < Nfaces; f++) {
            /* vertex index */
            int l1 = k*Np + (int) (Fmask[f + 0*Nfaces] - 1);
            int l2 = k*Np + (int) (Fmask[f + (Nfp-1)*Nfaces] - 1);
            
            /* mean value on edge */

            real dx = (real) (x[l2] - x[l1]);
            real dy = (real) (y[l2] - y[l1]);

            qpx += (delta[f]+hmean[k]) * dy;
            qpy -= (delta[f]+hmean[k]) * dx;
        }
        qpx /= area[k];
        qpy /= area[k];

        GetLocalVar(Np, hmean[k], xc, yc, x+k*Np, y+k*Np, 
			qpx, qpy, hlim+k*Np);

        // for(i=0;i<Np;i++){
        // 	sk = k*Np + i;
        //     real dx = x[sk] - xc;
        //     real dy = y[sk] - yc;

        //     hlim[sk] = hmean[k] + dx*qpx + dy*qpy;
        // }
				
	}

	free(delta);
	free(neigh_xc);
	free(neigh_yc);
	free(neigh_xf);
	free(neigh_yf);
	free(face_mean);
	free(neigh_mean);

	free(hmean);
	free(area);
	free(xmean);
	free(ymean);
	free(w);
	free(ws);
	return;
}

/* 
 * modified minmod function of TVB limiter.
 * m = TVB_minmod(a1, a2)
 */
real TVB_minmod(real a1, real a2, real dx, real TVB_factor){
	real m, v = 1.5;
	real a[2];
	if(abs(a1)<TVB_factor*dx*dx){
		m = a1;
	}else{
		a[0] = a1; a[1] = a2;
		minmod(2, a, &m);
	}
	return m;
}