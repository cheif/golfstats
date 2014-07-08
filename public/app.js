var app = angular.module('golfcal', []);

app.controller('CalCtrl', function($scope, $http) {
    $scope.loading = false;
    $scope.create = function() {
        $scope.loading = true;
        console.log($scope.user);
        $http.post('/createCal/', $scope.user)
        .success(function(data){
            $scope.loading = false;
            $scope.created = true;
            $scope.calURL = data.url;
        }).error(function(data){
            $scope.loading = false;
        });
    };
});
