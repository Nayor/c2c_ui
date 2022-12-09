<template>
  <div class="section">
    <html-header :title="$gettext('Activity trackers')" />

    <h1 class="title is-1" v-translate>Configure activity trackers</h1>
    <p v-translate>
      Configure your connection to external services like Strava or your GPS device application to easily retrieve
      geometries.
    </p>

    <h2 class="title is-2">Applications</h2>

    <div v-if="statusError" class="notification is-danger">
      <span v-translate>An error occurred, connection status could not be retrieved. Please refresh the page.</span>
    </div>
    <div class="columns is-multiline">
      <div class="column is-4" v-for="application in applications" :key="application.name">
        <application-card
          :application="application"
          @configure="configure(application.name)"
          @revoke="revoke(application.name)"
        ></application-card>
      </div>
    </div>

    <h2 class="title is-2">Last activities</h2>
    <template v-if="activities.length">
      <div v-for="activity in activities" :key="activity.id">
        {{ $dateUtils.toTechnicalString(activity.date) }}&hairsp;&bull;&hairsp;<template v-if="activity.name"
          >{{ activity.name }}&hairsp;&bull;&hairsp;</template
        >{{ activity.type[$user.lang] }}&hairsp;&bull;&hairsp;{{ $gettext(activity.vendor) }}
      </div>
    </template>
    <div v-else-if="activitiesLoading"><span v-translate>Loading...</span></div>
    <div v-else-if="activitiesError">
      <span v-translate>An error occurred, could not retrieve activities</span>
    </div>
    <div v-else v-translate>No activity retrieved yet. Have you connected your trackers?</div>
  </div>
</template>

<script>
import { toast } from 'bulma-toast';

import ApplicationCard from '@/components/tracking/ApplicationCard';
import trackingService from '@/js/apis/tracking-service';

export default {
  components: { ApplicationCard },

  data() {
    return {
      trackingService,
      activitiesLoading: null,
      activitiesError: false,
      activities: [],
      statusError: false,
      applications: [],
    };
  },

  computed: {
    baseUrl() {
      return window.location.origin;
    },
  },

  mounted() {
    this.applications = [
      {
        // $gettext('strava')
        name: 'strava',
        website: 'https://www.strava.com',
        connect: `https://www.strava.com/oauth/authorize?client_id=63968&response_type=code&approval_prompt=force&scope=activity:read,activity:read_all&redirect_uri=${this.baseUrl}/trackers/strava/exchange-token`,
        status: 'not-configured',
      },
      {
        // $gettext('decathlon')
        name: 'decathlon',
        website: 'https://developers.decathlon.com/products/sports-tracking-data',
        connect: `https://api-global.decathlon.net/connect/oauth/authorize?client_id=b708af3b-fd46-41ab-af73-5176a0a56f92&response_type=code&state=c2c&redirect_uri=${this.baseUrl}/trackers/decathlon/exchange-token`,
        status: 'not-configured',
      },
      {
        // $gettext('garmin')
        name: 'garmin',
        website: 'https://www.garmin.com/',
        status: 'not-configured',
      },
      {
        // $gettext('suunto')
        name: 'suunto',
        website: 'https://app.suunto.com/',
        connect: `https://cloudapi-oauth.suunto.com/oauth/authorize?response_type=code&client_id=2928e564-85eb-4aef-92fb-2a0259589c9c&redirect_uri=${this.baseUrl}/trackers/suunto/exchange-token`,
        status: 'not-configured',
      },
      {
        // $gettext('polar')
        name: 'polar',
        website: 'https://www.flow.polar.com/',
        connect: `https://flow.polar.com/oauth2/authorization?response_type=code&client_id=5a9f9ddd-fc15-48d2-bc56-86b43d491cc9&redirect_uri=${this.baseUrl}/trackers/polar/exchange-token`,
        status: 'not-configured',
      },
    ];
    this.load();
  },

  methods: {
    load() {
      this.loadActivities();
      const error = this.$route.query['error'];
      if (error) {
        // $gettext('auth-denied', 'tracking')
        // $gettext('unsufficient-scopes', 'tracking')
        // $gettext('setup-failed', 'tracking')
        // $gettext('unknown', 'tracking')
        toast({ message: this.$gettext(error, 'tracking'), type: 'is-danger', position: 'center' });
      }
    },

    loadActivities() {
      this.statusError = false;
      this.activitiesError = false;
      this.trackingService.getStatus(this.$user.id).then(
        (response) => {
          Object.entries(response.data).map(([app, status]) => {
            const idx = this.applications.findIndex(({ name }) => name === app);
            this.applications.splice(idx, 1, { ...this.applications[idx], status });
          });
          this.activitiesLoading = true;
          this.activitiesError = false;
          this.activities = [];
          this.trackingService.getActivities(this.$user.id, this.$user.lang).then(
            ({ data }) => {
              this.activitiesLoading = false;
              this.activities = data.slice(0, 5);
            },
            () => {
              this.activitiesLoading = false;
              this.activitiesError = true;
            }
          );
        },
        () => {
          this.statusError = true;
        }
      );
    },

    configure(vendor) {
      if (vendor === 'garmin') {
        this.configureGarmin();
      } else {
        window.location.href = this.applications.find(({ name }) => vendor === name).connect;
      }
    },

    configureGarmin() {
      this.trackingService.requestGarminUnauthorizeRequestToken(this.$user.id).then(
        ({ data }) => {
          const token = data.token;
          window.location.href = `https://connect.garmin.com/oauthConfirm?oauth_token=${token}&oauth_callback=${this.baseUrl}/trackers/garmin/exchange-token`;
        },
        () => {
          toast({ message: this.$gettext('setup-failed', 'tracking'), type: 'is-danger', position: 'center' });
        }
      );
    },

    revoke(vendor) {
      this.trackingService
        .deauthorize(vendor, this.$user.id)
        .then(() => {
          toast({ message: this.$gettext('Subcription revoked'), type: 'is-primary', position: 'top-center' });
          this.loadActivities(); // async
        })
        .catch(() => {
          toast({ message: this.$gettext('Subcription revokal failed'), type: 'is-danger', position: 'top-center' });
        });
    },
  },
};
</script>

<style scoped lang="scss">
.title.is-2 {
  border-bottom: 1px solid #ddd;
}
</style>