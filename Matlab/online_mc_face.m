
clear
%close all


%% community example
[Xn,y] = load_coil20_full;
Xn = reshape(Xn(:,1),128,128);
Xn = Xn(1:120,1:120)/255;
X = Xn;
p = 0.4;  % fraction of observations used

%divide between test and train (train 40%, test remaining 60%)
[y_train, mask_train, y_val, mask_val, y_test, mask_test] = split_observed(X, [p, 1-p, 0]);
mask_train = reshape(mask_train,size(X,1),size(X,2));
mask_test = 1 - mask_train;
mask_test = reshape(mask_test,size(X,1),size(X,2));
Xtrain = mask_train.*Xn;
Xtest = X - Xtrain;

%% rescale
[Xtrain, y_lims_init] = rescale_mc(Xtrain,mask_train);

%% add noise

X_noisy = Xtrain + 0.1*randn(size(X,1),size(X,2)).*mask_train;


%%
gamma =[0.5 0.5]*0.2;
Ninit = 10;
batch = 10;
iters = 10;
a_final = [1:size(X,2)];

T_gctp = X_noisy;
for i = 1 : 5
    a = randperm(size(T_gctp,2));
    mask_train = mask_train(:,a);
    mask_test = mask_test(:,a);
    X_noisy = X_noisy(:,a);
    T_gctp = T_gctp(:,a);
    Xtest = Xtest(:,a);
    T_gctp(mask_train) = X_noisy(mask_train);
    T_gctp = gsp_fastmc_2g_online_knn2(T_gctp, mask_train, gamma(1),gamma(2), Ninit, batch, iters, 0,0);
    a_final = a_final(a);
end

[a_final,ind_final] = sort(a_final,'ascend');
mask_train = mask_train(:,ind_final);
mask_test = mask_test(:,ind_final);
X_noisy = X_noisy(:,ind_final);
T_gctp = T_gctp(:,ind_final);
Xtest = Xtest(:,ind_final);

T_gctp = lin_map(T_gctp, y_lims_init);
A = Xtest; B = T_gctp.*mask_test;
A(A == 0) = nan; B(B == 0) = nan;
disp(['RMSE:' num2str( rmse(A,B))])

figure; subplot(131); imagesc(X_noisy); title('actual noisy matrix');
subplot(132); imagesc(T_gctp); title(['online knn update: error =' num2str(rmse(A,B))]);




