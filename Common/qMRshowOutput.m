function qMRshowOutput(FitResults,data,Model)
% Show mid-slice fitting maps
% Also show a fit in the center voxel

outputIm = FitResults.(FitResults.fields{1});
figure();

 if length(size(outputIm))>2
   
  sz = size(outputIm);
  szz = round(sz(3)/2);
  imagesc(imrotate(outputIm(:,:,szz),90)); colormap('jet');  title(FitResults.fields{1});
    climm = prctile(outputIm(:),10);
    climM = prctile(outputIm(:),10);
    caxis([climm max(climm*1.01,climM)]); colorbar();
 else 
    imagesc(imrotate(outputIm,90)); colormap('jet');  title(FitResults.fields{1});
    caxis([prctile(outputIm(:),10) prctile(outputIm(:),90)]); colorbar();

 end

if FitResults.Model.voxelwise 
    
    row = round(size(outputIm,1)/2);
    col = round(size(outputIm,2)/2);
    slice = round(size(outputIm,3)/2);
 
    voxel = [row, col, slice]; % check center voxel
    FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
    dataVox         = extractvoxel(data,voxel);

    figure();
    Model.plotModel(FitResultsVox,dataVox)
    
end



end 