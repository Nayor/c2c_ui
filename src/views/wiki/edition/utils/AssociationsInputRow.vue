<template>
  <div>
    <div class="columns is-multiline">
      <div class="column is-narrow">
        <label class="label">
          {{ (label || $gettext(field.name)) | uppercaseFirstLetter }}
          <marker-helper :name="helper ? helper : field.helper" />
        </label>
      </div>
      <div class="column is-narrow">
        <form-input
          class="is-expanded"
          ref="input"
          :document="document"
          :field="field"
          @add="$emit('add', arguments[0])"
          :options-filter="optionsFilter"
        />
      </div>
    </div>
    <div class="columns is-multiline">
      <template v-for="child in document.associations[field.name]">
        <div v-if="cardsFilter(child)" :key="child.document_id" class="column is-4">
          <document-card
            :document="child"
            :show-delete-button="showDeleteButton(child)"
            @delete="$documentUtils.removeAssociation(document, child)"
            target="_blank"
          />
        </div>
      </template>
    </div>
  </div>
</template>

<script>
import FormInput from './FormInput';

import associationRights from '@/js/associations-rights-mixin';
import { requireDocumentProperty, requireFieldProperty } from '@/js/properties-mixins';

export default {
  components: {
    FormInput,
  },

  mixins: [requireFieldProperty, requireDocumentProperty, associationRights],

  props: {
    label: {
      type: String,
      default: null,
    },

    helper: {
      type: String,
      default: undefined, // default must be undefined. null means explicit no helper
    },

    cardsFilter: {
      type: Function,
      default: () => true,
    },

    optionsFilter: {
      type: Function,
      default: (doc) => doc,
    },
  },

  computed: {
    visible() {
      return this.$refs.input.visible;
    },
    hasError() {
      return this.field.error !== null;
    },
  },

  methods: {
    showDeleteButton(document) {
      return this.canRemove(this.document, document);
    },
  },
};
</script>
