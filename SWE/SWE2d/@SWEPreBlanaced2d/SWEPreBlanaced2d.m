classdef SWEPreBlanaced2d < SWEAbstract2d
    
    properties(Constant)
        %> Variable field - {h, hu, hv, b, eta}
        Nfield = 5
        %> Variable field - {h, hu, hv}
        Nvar = 3
        %> field index of variable field
        varFieldIndex = [ 1,2,3 ]
    end
    
    methods
        function [ E, G ] = matEvaluateFlux( obj, mesh, fphys )
            [ E, G ] = mxEvaluateFlux2d( obj.hmin, obj.gra, mesh.EToR, fphys );
        end
    end
    
    methods( Access = protected )
        function matEvaluateTopographySourceTerm( obj, fphys )
            for m = 1:obj.Nmesh
                mesh = obj.meshUnion(m);
                obj.frhs{m} = obj.frhs{m} + mxEvaluateSourceTopography2d...
                    ( obj.gra, mesh.EToR, fphys{m}, obj.zGrad{m} );
            end
        end
        
        function fphys = matEvaluateLimiter( obj, fphys )
            fphys = obj.limiter.matLimit( fphys, 2 );
            fphys = obj.limiter.matLimit( fphys, 3 );
            for m = 1:obj.Nmesh % update new elevation
                fphys{m}(:,:,5) = fphys{m}(:,:,1) + fphys{m}(:,:,4);
            end
            fphys = obj.limiter.matLimit( fphys, 5 ); % enforce the elevation
            for m = 1:obj.Nmesh % update new elevation
                mesh = obj.meshUnion(m);
                ind = (mesh.EToR == int8( NdgRegionType.Wet ));
                fphys{m}(:,ind,1) = fphys{m}(:,ind,5) - fphys{m}(:,ind,4);
%                 fphys{m}(:,:,1) = fphys{m}(:,:,5) - fphys{m}(:,:,4);
            end
%             for m = 1:obj.Nmesh % set the new bottom topography
%                 mesh = obj.meshUnion(m);
%                 ind = (mesh.EToR == int8( NdgRegionType.Wet ));
%                 fphys{m}(:,ind,4) = fphys{m}(:,ind,7) - fphys{m}(:,ind,1);
%                 br = mesh.cell.Dr * obj.fphys{m}(:,ind,4);
%                 bs = mesh.cell.Ds * obj.fphys{m}(:,ind,4);
%                 fphys{m}(:,ind,5) = mesh.rx(:, ind) .* br + mesh.sx(:, ind) .* bs;
%                 fphys{m}(:,ind,6) = mesh.ry(:, ind) .* br + mesh.sy(:, ind) .* bs;
%             end
        end
    end
    
end

