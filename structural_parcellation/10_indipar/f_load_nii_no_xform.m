function [nii] = f_load_nii_no_xform(filename)
img_idx = []; 
old_RGB = 0;

[nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr_gz(filename);
[nii.img,nii.hdr] = load_nii_img(nii.hdr,nii.filetype,...
    nii.fileprefix,nii.machine,img_idx,'','','',old_RGB);
hdr = nii.hdr;

useForm=[];				
if hdr.hist.sform_code > 0
    useForm='s';
elseif hdr.hist.qform_code > 0
    useForm='q';
end

   if isequal(useForm,'s')
      R = [hdr.hist.srow_x(1:3)
           hdr.hist.srow_y(1:3)
           hdr.hist.srow_z(1:3)];

      T = [hdr.hist.srow_x(4)
           hdr.hist.srow_y(4)
           hdr.hist.srow_z(4)];

      nii.hdr.hist.old_affine = [ [R;[0 0 0]] [T;1] ];

   elseif isequal(useForm,'q')
      b = hdr.hist.quatern_b;
      c = hdr.hist.quatern_c;
      d = hdr.hist.quatern_d;

      if 1.0-(b*b+c*c+d*d) < 0
         if abs(1.0-(b*b+c*c+d*d)) < 1e-5
            a = 0;
         else
            error('Incorrect quaternion values in this NIFTI data.');
         end
      else
         a = sqrt(1.0-(b*b+c*c+d*d));
      end

      qfac = hdr.dime.pixdim(1);
      i = hdr.dime.pixdim(2);
      j = hdr.dime.pixdim(3);
      k = qfac * hdr.dime.pixdim(4);

      R = [a*a+b*b-c*c-d*d     2*b*c-2*a*d        2*b*d+2*a*c
           2*b*c+2*a*d         a*a+c*c-b*b-d*d    2*c*d-2*a*b
           2*b*d-2*a*c         2*c*d+2*a*b        a*a+d*d-c*c-b*b];

      T = [hdr.hist.qoffset_x
           hdr.hist.qoffset_y
           hdr.hist.qoffset_z];

      nii.hdr.hist.old_affine = [ [R * diag([i j k]);[0 0 0]] [T;1] ];

   elseif nii.filetype == 0 && exist([nii.fileprefix '.mat'],'file')
      load([nii.fileprefix '.mat']);	% old SPM affine matrix
      R=M(1:3,1:3);
      T=M(1:3,4);
      T=R*ones(3,1)+T;
      M(1:3,4)=T;
      nii.hdr.hist.old_affine = M;

   else
      M = diag(hdr.dime.pixdim(2:5));
      M(1:3,4) = -M(1:3,1:3)*(hdr.hist.originator(1:3)-1)';
      M(4,4) = 1;
      nii.hdr.hist.old_affine = M;
   end

   return					% load_nii_no_xform
%% ============================================================ %%