classdef NdgQuadFreeStrongFormAdvSolver2d < NdgQuadFreeStrongFormSolver & ...
        NdgAbstractAdvSolver
    
    methods
        function obj = NdgQuadFreeStrongFormAdvSolver2d( phys )
            obj = obj@NdgQuadFreeStrongFormSolver( phys );
            obj = obj@NdgAbstractAdvSolver(phys);
        end
        %> Call the flux subroutine from the NdgPhys object.
        function evaluateAdvectionRHS( obj, fphys )
            phys = obj.phys;
            for m = 1:phys.Nmesh % calculate RHS term on each mesh
                mesh = phys.meshUnion(m);
                [ E, G ] = phys.matEvaluateFlux( mesh, fphys{m} );
                [ fm, fp ] = phys.matEvaluateSurfaceValue( mesh, fphys{m}, phys.fext{m} );
                [ fluxS ] = phys.matEvaluateSurfNumFlux( mesh, obj.nx{m}, obj.ny{m}, fm, fp );
                [ flux ] = phys.matEvaluateSurfFlux( mesh, obj.nx{m}, obj.ny{m}, fm );
                
                for i = 1:phys.Nvar
                    [ phys.frhs{m}(:,:,i) ] = ...
                        - obj.rx{m}.*( obj.Dr{m} * E(:,:,i) ) ...
                        - obj.sx{m}.*( obj.Ds{m} * E(:,:,i) ) ...
                        - obj.ry{m}.*( obj.Dr{m} * G(:,:,i) ) ...
                        - obj.sy{m}.*( obj.Ds{m} * G(:,:,i) ) ...
                        + ( obj.LIFT{m} * ( obj.Js{m} .* ( flux(:,:,i) - fluxS(:,:,i) ) ))./ obj.J{m};
                end
            end
        end
    end
    
end

