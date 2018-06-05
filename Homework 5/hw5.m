%% Homework 5, ECE283, Morten Lie. Collaboration with Sondre Kongsg�rd, Brage S�ther, Anders Vagle

clear all;
close all;
clc;
addpath('functions');

%% Parameters
N = 200;
d = 100;
u = zeros(d, 6);
sigma2 = 0.01;
K_max = 5;
n_rand_inits = 5;

%% Data generation
for j = 1:6
    u(:,j) = generate_random_vector(d);
    while check_orthogonality(u,j) == 0
        u(:,j) = generate_random_vector(d);
    end
end

[X_d, Z_d] = generate_sample_data(u,sigma2,N);

%% Part 1, Single value decomposision
[U,S,V] = svd(X_d);

eig_mean = eigenvalue_mean(S);
d0 = 0;
for d0 = 0:d
    if S(d0+1,d0+1) < eig_mean
        break
    end
end
fprintf(['Number of dominant singular values: ' num2str(d0) '\n']);

%% Part 1, PCA
S_r = zeros(d0,d0);
for i = 1:d0
    S_r(i,i) = S(i,i);
end
U_r = U(:,1:d0);
V_r = V(:,1:d0);
X_r = U_r*S_r*V_r';
X_d0 = X_r*V_r;

%% d-dimensional k-means
m_opt_d0 = zeros(K_max,size(X_d0,2),K_max);
C_opt_d0 = zeros(N,K_max);
for K = 2:K_max  
    min_sme = inf;
    for i = 1:n_rand_inits
        C_d0 = randi(K,N,1);
        [m_d0,C_d0] = k_means(N,K,C_d0,X_d0);
        sme = SME(m_d0,X_d0,C_d0);
        if sme < min_sme
            m_opt_d0(1:K,:,K) = m_d0;
            C_opt_d0(:,K) = C_d0;
            min_sme = sme;
        end
    end
end

% One-hot encoding
a = zeros(N,K_max,K_max);
for K = 2:K_max
    for i = 1:N     
        a(i,C_opt_d0(i,K),K) = 1;
    end
end

%% Generate empirical probability table for d-dimensional data
pk_kmeans_d = zeros(3,K_max,K_max);
for K = 2:K_max
    for l = 1:3
        for k = 1:K
            num_k_l = 0;
            num_l = 0;
            for i = 1:N
                if Z_d(i,l) == 1
                    num_l = num_l + 1;
                    if a(i,k,K) == 1
                        num_k_l = num_k_l + 1;
                    end
                end
            end
            pk_kmeans_d(l,k,K) = num_k_l/num_l;         
        end
    end
end
plot_table(pk_kmeans_d,K_max,'d-dimensional K-means');

%% Random Projections and Compressed Sensing
m = 10; %To be determined
phi = zeros(m,d);
for i = 1:m
    for j = 1:d
        if rand < 0.5
            phi(i,j) = -1;
        else
            phi(i,j) = 1;
        end
    end
end

n_draws = 10;
lambdas = [0.001 0.01 0.1 1 10];
norm_MSE = zeros(length(lambdas),1);
for draw = 1:n_draws
    [S, Z] = generate_sample_data(u,0,N); %Sigma = 0 to remove noise component implemented in function, if we need S later??
    noise_matrix = normrnd(0,sigma2*eye(d));
    for j = 1:d
        noise(j) = noise_matrix(j,j);
    end
    X = S + noise;
    y = 1/sqrt(m)*phi*X';
    y = 1/sqrt(m)*phi*X';
    B = [u(:,1) u(:,2) u(:,3) u(:,4) u(:,5) u(:,6)]; 
    lasso_mat = 1/sqrt(m)*phi*B;
    for i = 1:length(lambdas)
        lambda = lambdas(i);
        a_hat = lasso_func(lasso_mat,y,lambda);
        S_hat = (B*a_hat')';
        % FIND OUT WHICH CLASS THE S BELONG TO, AND COMPUTE 3 DIFFERENT
        % NORMALIZED MSE
        norm_MSE(i) = norm_MSE(i) + immse(S,S_hat)/sum(sum(S.^2));
    end
end
norm_MSE = norm_MSE./n_draws;

%% Plotting
figure(1)
plot(lambdas,norm_MSE,'Linewidth',1.5);
xlabel('\lambda')
ylabel('Normalized MSE');


%% Comments
% All eigenvalues that were greater than the mean were given the property
% as a dominant eigenvalue. 
% When we increase N, we say that d ....

% Geometric insight...
