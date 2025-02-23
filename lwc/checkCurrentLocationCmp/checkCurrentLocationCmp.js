import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import handleValidateCurrentLocation from '@salesforce/apex/CheckCurrentLocationCmpController.handleValidateCurrentLocation';
import helperUpdateLocationDetails from '@salesforce/apex/CheckCurrentLocationCmpController.helperUpdateLocationDetails';

export default class CheckCurrentLocationCmp extends LightningElement {
    @track latitude;
    @track longitude;
    @track locationAvailable = false;
    @track error = '';
    @track permissionStatus = '';
    @track AccountRecordLatLong;
    @api recordId;

    connectedCallback() {
        if (!this.recordId) {
            const urlParams = window.location.href;
            console.log('urlParams::', urlParams);

            const recordIdMatch = urlParams.match(/\/r\/\w+\/([a-zA-Z0-9]{15,18})\//);
            if (recordIdMatch && recordIdMatch.length > 1) {
                this.recordId = recordIdMatch[1];
                console.log('Record ID:', this.recordId);
            } else {
                console.warn('Record ID not found in the URL.');
            }
        }
    }


    // Checks for browser's geolocation permission's
    handleCheckLocation() { // TODO : Change the method to something like 'checkBrowserGeolocationPermission'
        // Native browser API to query the permissions granted for specific browser features
        console.log(' handleCheckLocation navigator', navigator);
        console.log(' handleCheckLocation navigator', JSON.stringify(navigator,null,2));
        console.log(' handleCheckLocation navigator.permissions', navigator.permissions); // undefined 
        console.log(' handleCheckLocation navigator.permissions', JSON.stringify(navigator.permissions, null, 2)); // undefined 
        if (navigator.permissions) { // CONDOTION : FALSE
            // checks the current permission status for geolocation
            navigator.permissions.query({ name: 'geolocation' })
                .then((result) => {
                    console.log('handleCheckLocation result ::: ', JSON.stringify(result,null,2));
                    this.permissionStatus = result.state;
                    if (result.state === 'granted' || result.state === 'prompt') {
                        this.getLocation();
                    } else if (result.state === 'denied') {
                        this.error = 'User has denied the request for Geolocation. Please update your browser settings to allow location access.';
                    }
                    result.onchange = () => {
                        this.permissionStatus = result.state;
                    };
                });
        } else {
            console.log('navigator.permissions is NUll')
            this.getLocation();
        }
    }

    // Gets the location of the agent using the browser's geolocation object
    getLocation() {
        console.log(' getLocation navigator', navigator);
        console.log(' getLocation navigator', JSON.stringify(navigator, null, 2));
        console.log(' getLocation navigator.geolocation', navigator.geolocation);
        console.log(' getLocation navigator.geolocation', JSON.stringify(navigator.geolocation, null, 2));
        
        // Checks geolocation object 
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    console.log('getLocation position:::', position);
                    console.log('getLocation position.coords.latitude :::', position.coords.latitude);  // ISSUE : WRONG COORDINATES
                    console.log('getLocation position.coords.longitude :::', position.coords.longitude);// ISSUE : WRONG COORNINATES
                    console.log('Accuracy:', position.coords.accuracy);


                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.locationAvailable = true;
                    this.error = '';
                    this.checkLocationDetailsWithRecord();

                },
                (error) => {
                    this.handleLocationError(error);
                },
                { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 } // Enhancing accuracy

            );
        } else {
            this.error = 'Geolocation is not supported by this browser.';
            this.locationAvailable = false;
        }
    }

    //
    checkLocationDetailsWithRecord() {
        const accountRecordLatLong = {
            latitude: this.latitude.toString(),
            longitude: this.longitude.toString(),
            recordId: this.recordId
        };

        console.log('checkLocationDetailsWithRecord accountRecordLatLong :::', JSON.stringify(accountRecordLatLong, null, 2));

        handleValidateCurrentLocation({ accountDetails: JSON.stringify(accountRecordLatLong) })
            .then((result) => {
                console.log('checkLocationDetailsWithRecord result ::: ', JSON.stringify(result, null, 2));
                if (result.isSuccess) {
                    console.log('result.response ::', JSON.stringify(result.response, null, 2));
                    this.handleUpdateLocationDetails();
                } else {
                    this.showToast('Error', 'Unexpected Error', result.response)
                }
            })
            .catch((error) => {
               // this.error = 'An error occurred: ' + error.body.message;
                this.showToast('Error', 'Unexpected Error', 'error.body.message')
                console.error(error);
            });
    }


    handleUpdateLocationDetails() {
        helperUpdateLocationDetails({ recordId: this.recordId })
            .then((result) => {
                console.log('Response from Apex:96', JSON.stringify(result, null, 2));
                if (result.isSuccess) {
                    this.showToast('Success', result.message, 'Updated Succesafully')
                    console.log('Response::', JSON.stringify(result.response, null, 2));
                } else {
                    this.showToast('Error', 'Unexpected Error', result.message)
                }
            })
            .catch((error) => {
                this.error = 'An error occurred: ' + error.body.message;
                this.showToast('Error', 'Unexpected Error', error.body.message)
                console.error(error);
            });
    }
    handleLocationError(error) {
        switch (error.code) {
            case error.PERMISSION_DENIED:
                this.error = 'User denied the request for Geolocation.';
                break;
            case error.POSITION_UNAVAILABLE:
                this.error = 'Location information is unavailable.';
                break;
            case error.TIMEOUT:
                this.error = 'The request to get user location timed out.';
                break;
            case error.UNKNOWN_ERROR:
                this.error = 'An unknown error occurred while retrieving the location.';
                break;
            default:
                this.error = 'An unexpected error occurred.';
        }
        this.locationAvailable = false;
    }

    get showLocation() {
        return this.locationAvailable && !this.error;
    }

    get showError() {
        return this.error && !this.locationAvailable;
    }

    get showPermissionPrompt() {
        return this.permissionStatus === 'prompt';
    }

    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }

}

/*
NITIN'S ORIGINAL CODE 
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import handleValidateCurrentLocation from '@salesforce/apex/CheckCurrentLocationCmpController.handleValidateCurrentLocation';
import helperUpdateLocationDetails from '@salesforce/apex/CheckCurrentLocationCmpController.helperUpdateLocationDetails';

export default class CheckCurrentLocationCmp extends LightningElement {
    @track latitude;
    @track longitude;
    @track locationAvailable = false;
    @track error = '';
    @track permissionStatus = '';
    @track AccountRecordLatLong;
    @api recordId;

    connectedCallback() {
        if (!this.recordId) {
            const urlParams = window.location.href;
            console.log('urlParams::', urlParams);

            const recordIdMatch = urlParams.match(/\/r\/\w+\/([a-zA-Z0-9]{15,18})\//);
            if (recordIdMatch && recordIdMatch.length > 1) {
                this.recordId = recordIdMatch[1];
                console.log('Record ID:', this.recordId);
            } else {
                console.warn('Record ID not found in the URL.');
            }
        }
    }

    handleCheckLocation() {
        // native browser API to query the permissions granted for specific browser features
        if (navigator.permissions) {
            // checks the current permission status for geolocation
            navigator.permissions.query({ name: 'geolocation' })
                .then((result) => {
                    this.permissionStatus = result.state;
                    if (result.state === 'granted' || result.state === 'prompt') {
                        this.getLocation();
                    } else if (result.state === 'denied') {
                        this.error = 'User has denied the request for Geolocation. Please update your browser settings to allow location access.';
                    }
                    result.onchange = () => {
                        this.permissionStatus = result.state;
                    };
                });
        } else {
            this.getLocation();
        }
    }

    getLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.locationAvailable = true;
                    this.error = '';
                    this.checkLocationDetailsWithRecord();

                },
                (error) => {
                    this.handleLocationError(error);
                },
                { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 } // Enhancing accuracy

            );
        } else {
            this.error = 'Geolocation is not supported by this browser.';
            this.locationAvailable = false;
        }
    }

    checkLocationDetailsWithRecord() {
        const accountRecordLatLong = {
            latitude: this.latitude.toString(),
            longitude: this.longitude.toString(),
            recordId: this.recordId
        };

        handleValidateCurrentLocation({ accountDetails: JSON.stringify(accountRecordLatLong) })
            .then((result) => {
                console.log('Response from Apex:77', JSON.stringify(result, null, 2));
                if (result.isSuccess) {
                    console.log('Response::', JSON.stringify(result.response, null, 2));
                    this.handleUpdateLocationDetails();
                } else {
                    this.showToast('Error', 'Unexpected Error', result.response)
                }
            })
            .catch((error) => {
               // this.error = 'An error occurred: ' + error.body.message;
                this.showToast('Error', 'Unexpected Error', 'error.body.message')
                console.error(error);
            });
    }


    handleUpdateLocationDetails() {
        helperUpdateLocationDetails({ recordId: this.recordId })
            .then((result) => {
                console.log('Response from Apex:96', JSON.stringify(result, null, 2));
                if (result.isSuccess) {
                    this.showToast('Success', result.message, 'Updated Succesafully')
                    console.log('Response::', JSON.stringify(result.response, null, 2));
                } else {
                    this.showToast('Error', 'Unexpected Error', result.message)
                }
            })
            .catch((error) => {
                this.error = 'An error occurred: ' + error.body.message;
                this.showToast('Error', 'Unexpected Error', error.body.message)
                console.error(error);
            });
    }
    handleLocationError(error) {
        switch (error.code) {
            case error.PERMISSION_DENIED:
                this.error = 'User denied the request for Geolocation.';
                break;
            case error.POSITION_UNAVAILABLE:
                this.error = 'Location information is unavailable.';
                break;
            case error.TIMEOUT:
                this.error = 'The request to get user location timed out.';
                break;
            case error.UNKNOWN_ERROR:
                this.error = 'An unknown error occurred while retrieving the location.';
                break;
            default:
                this.error = 'An unexpected error occurred.';
        }
        this.locationAvailable = false;
    }

    get showLocation() {
        return this.locationAvailable && !this.error;
    }

    get showError() {
        return this.error && !this.locationAvailable;
    }

    get showPermissionPrompt() {
        return this.permissionStatus === 'prompt';
    }

    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }

}
    */