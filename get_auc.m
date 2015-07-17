function auc = get_auc (data)

% calculate confusion matrix for many thresholds
%thresholds = [-100; unique(data(:, 1))];
thresholds = [min(data(:, 1)) - 1; unique(data(:, 1)); max(data(:, 1)) + 1];

for t = 1 : length(thresholds)
    % learning is done, we can see what is the prediction like
    q = find(data(:, 1) >= thresholds(t));
    prediction(q) = 1;
    q = find(data(:, 1) < thresholds(t));
    prediction(q) = 0;

    pred_error = prediction' - data(:, 2);

    % determine elements of the confusion matrix
    q00(t) = length(find(pred_error == 0 & data(:, 2) == 0));
    q01(t) = length(find(pred_error ~= 0 & data(:, 2) == 1)); % predicted 0, true 1
    q10(t) = length(find(pred_error ~= 0 & data(:, 2) == 0));
    q11(t) = length(find(pred_error == 0 & data(:, 2) == 1));
end

% calculate AUC
sn = q11 ./ (q01 + q11); % store sensitivity array
sp = q00 ./ (q10 + q00); % store specificity array

snn = sn(length(sn) : -1 : 1);
spp = 1 - sp;
spp = spp(length(spp) : -1 : 1);

auc = trapz(spp, snn);

%plot(spp, snn)

return