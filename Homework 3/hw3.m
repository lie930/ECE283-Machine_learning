clear all;
close all;
clc;

%% Component definitions
N = 200;

% Component 1
theta_1 = 0;
m_1 = [0 0]';
pi_1 = 1/2;
lambda_1 = 2;
lambda_2 = 1;
u_1 = [cos(theta_1) sin(theta_1)]';
u_2 = [-sin(theta_1) cos(theta_1)]';
C_1 = [u_1 u_2]*diag([lambda_1,lambda_2])*inv([u_1 u_2]);

% Component 2
theta2_2 = -3*pi/4;
m_2 = [-2 1]';
pi_2 = 1/6;
lambda_a1 = 2;
lambda_a2 = 1/4;
u1_2 = [cos(theta2_2) sin(theta2_2)]';
u2_2 = [-sin(theta2_2) cos(theta2_2)]';
C_2 = [u1_2 u2_2]*diag([lambda_a1,lambda_a2])*inv([u1_2 u2_2]);

% Component 3
theta2_3 = pi/4;
m_3 = [3 2]';
pi_3 = 1/3;
lambda_b1 = 3;
lambda_b2 = 1;
u1_3 = [cos(theta2_3) sin(theta2_3)]';
u2_3 = [-sin(theta2_3) cos(theta2_3)]';
C_3 = [u1_3 u2_3]*diag([lambda_b1,lambda_b2])*inv([u1_3 u2_3]);


X = zeros(N,2);
Z = zeros(N,3);
for i = 1:N
    a = rand();
    if a < pi_1
        X(i,:) = mvnrnd(m_1,C_1);
        Z(i,:) = [1 0 0];
    elseif a < pi_1 + pi_2
        X(i,:) = mvnrnd(m_2,C_2);
        Z(i,:) = [0 1 0];
    else 
        X(i,:) = mvnrnd(m_3,C_3);
        Z(i,:) = [0 0 1];
    end
end


%% K-means
N_rand_inits = 5;
K_max = 5;  
m_opt = zeros(K_max,2,K_max);
C_opt = zeros(N,K_max);
for K = 2:K_max  
    min_sme = inf;
    for i = 1:N_rand_inits
        C = randi(K,N,1);
        [m,C] = k_means(N,K,C,X);
        sme = SME(m,X,C);
        if sme < min_sme
            m_opt(1:K,:,K) = m;
            C_opt(:,K) = C;
            min_sme = sme;
        end
    end
end

% One-hot encoding
a = zeros(N,K_max,K_max);
for K = 2:K_max
    for i = 1:N     
        a(i,C_opt(i,K),K) = 1;
    end
end

%% Generate empirical probability table
pk_kmeans = zeros(3,K_max,K_max);
for K = 2:K_max
    for l = 1:3
        for k = 1:K
            num_k_l = 0;
            num_l = 0;
            for i = 1:N
                if Z(i,l) == 1
                    num_l = num_l + 1;
                    if a(i,k,K) == 1
                        num_k_l = num_k_l + 1;
                    end
                end
            end
            pk_kmeans(l,k,K) = num_k_l/num_l;         
        end
    end
end
plot_table(pk_kmeans,K_max,'K-means');

%% EM
m_EM = zeros(K_max,2,K_max);
C_EM = zeros(2,2,K_max, K_max);
pi_EM = zeros(K_max,K_max);
pk_EM = zeros(3,K_max,K_max);
for K = 2:K_max
    m_init = m_opt(:,:,K);
    [m_,C_,pi_,pk_] = EM(m_init,N,K,X,Z);
    m_EM(:,:,K) = m_;
    C_EM(:,:,1:K,K) = C_;
    pi_EM(1:K,K) = pi_;
    pk_EM(:,1:K,K) = pk_;
end
plot_table(pk_EM,K_max,'EM');


%% Generate a random vector u in d dimensions
d = 30;
u = zeros(d, 7);
for j = 1:7
    u(:,j) = generate_random_vector(d);
    while check_orthogonality(u,j) == 0
        u(:,j) = generate_random_vector(d);
    end
end

%% Generate d-dimensional data samples
sigma2 = 0.01;
N_d = 200;
[X_d, Z_d] = generate_sample_data(u,sigma2,N_d);

%% d-dimensional k-means
m_opt_d = zeros(K_max,size(X_d,2),K_max);
C_opt_d = zeros(N_d,K_max);
for K = 2:K_max  
    min_sme = inf;
    for i = 1:N_rand_inits
        C_d = randi(K,N_d,1);
        [m_d,C_d] = k_means(N_d,K,C_d,X_d);
        sme = SME(m_d,X_d,C_d);
        if sme < min_sme
            m_opt_d(1:K,:,K) = m_d;
            C_opt_d(:,K) = C_d;
            min_sme = sme;
        end
    end
end
%% Generate empirical probability table for d-dimensional data
pk_kmeans_d = zeros(3,K_max,K_max);
for K = 2:K_max
    for l = 1:3
        for k = 1:K
            num_k_l = 0;
            num_l = 0;
            for i = 1:N_d
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

%% d-dimentional EM
m_EM_d = zeros(K_max,2,K_max);
C_EM_d = zeros(2,2,K_max, K_max);
pi_EM_d = zeros(K_max,K_max);
pk_EM_d = zeros(3,K_max,K_max);
for K = 2:K_max
    m_init = m_opt(:,:,K);
    [m_,C_,pi_,pk_] = EM(m_init,N,K,X,Z);
    m_EM(:,:,K) = m_;
    C_EM(:,:,1:K,K) = C_;
    pi_EM(1:K,K) = pi_;
    pk_EM(:,1:K,K) = pk_;
end
plot_table(pk_EM,K_max,'EM');



%% Plotting
h = figure; set(h,'WindowStyle','docked');
subplot(2,3,1);
hold on;
for i = 1:N
    if Z(i,1) == 1
         scatter(X(i,1),X(i,2),'r')
    elseif Z(i,2) == 1
        scatter(X(i,1),X(i,2),'g');
    elseif Z(i,3) == 1
        scatter(X(i,1),X(i,2),'b');         
    end
end
scatter(m_1(1), m_1(2), 'r','filled');
scatter(m_2(1), m_2(2), 'g','filled');
scatter(m_3(1), m_3(2), 'b','filled');
title('Original components');
hold off;

colors = 'rbkmc'; 
x1 = min(X(:,1)):0.05:max(X(:,1));
x2 = min(X(:,2)):0.05:max(X(:,2));
[X1,X2] = meshgrid(x1,x2);

for K = 2:K_max
    C = C_opt(:,K);
    m = m_opt(:,:,K);
    subplot(2,3,K+1);
    hold on;
    for i = 1:N
        for k = 1:K
            if C(i) == k
                scatter(X(i,1),X(i,2),colors(k));   
            end
        end
    end
    for k = 1:K
        scatter(m(k,1), m(k,2),'filled',colors(k));

        F = mvnpdf([X1(:) X2(:)],m_EM(k,:,K),C_EM(:,:,k,K));
        F = reshape(F,length(x2),length(x1));
        contour(x1,x2,F,3,colors(k));
        scatter(m_EM(k,1,K),m_EM(k,2,K),'x',colors(k));
    end
    title(['K = ' num2str(K)]);
    hold off;
end
suptitle('Original components, K-means clusters and EM contours');

%% Comments
% Problem 4: A new vector is too correlated to another vector if the average absolute
% value of the product is greater than 0.2. (Based on experiements)