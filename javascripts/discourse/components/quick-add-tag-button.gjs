/* eslint-disable */
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";

import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";

import { eq, includes, or } from "truth-helpers";
/* eslint-enable */

export default class QuickAddTagButton extends Component {
  @service currentUser;
  @service toasts;

  @tracked user_groups = [];

  constructor() {
    super(...arguments);
    console.log(this.currentUser);
    // for (let grp in this.currentUser.groups) {
    //   this.user_groups.push(grp.name);
    // }
    console.log(settings.quick_add_tags_buttons);
  }

  @action
  async addTag(setting_button) {
    const topic = this.args.topic;
    const currentTags = topic.tags;
    const settingTags = setting_button.tags_to_add;

    let newTags = currentTags;

    settingTags.forEach((tag) => {
      if (!currentTags.includes(tag)) {
        newTags.push(tag);
      }
    });

    try {
      if (setting_button.auto_close_topic) {
        await ajax(`/t/${topic.id}/timer.json`, {
          type: "POST",
          data: {
            status_type: "close",
            time: setting_button.auto_close_topic_days * 24 // In hours, multiply by 24 to get days
          }
        });
      }
      await ajax(`/t/-/${topic.id}.json`, {
        type: "PUT",
        data: {
          tags: newTags,
          keep_existing_draft: true
        }
      // eslint-disable-next-line no-unused-vars
      }).then((response) => {
        this.toasts.success({
          duration: "short",
          data: {
            // eslint-disable-next-line no-undef
            message: I18n.t(themePrefix("added_tag_success_message")),
          },
        });
      });
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e);
      if (e.jqXHR.responseJSON.errors !== undefined) {
        const errors = e.jqXHR.responseJSON.errors;
        errors.forEach((error) => {
          this.toasts.error({
            duration: "short",
            data: {
              message: error
            },
          });
        });
      }
    }
  }

  <template>
    {{! We move the logic here, so that we can check if the button should show per button in the settings, since (I don't think) we can pass arguments into getters }}
    {{#each settings.quick_add_tags_buttons as |setting_button|}}
      {{! We check if the setting is even filled up in the first place }}
      {{#if setting_button.in_categories}}
        {{#if (includes setting_button.in_categories @topic.category_id)}}
          {{#if setting_button.auto_close_topic}}
            {{#if (or this.currentUser.moderator this.currentUser.admin (eq this.currentUser.trust_level 4))}}
              <DButton
                @action={{fn (this.addTag setting_button)}}
                @icon="tag"
                {{! @label={{themePrefix "quick_add_tag_button_text"}}
                {{! @title={{themePrefix "quick_add_tag_button_title"}}
                @translatedLabel={{setting_button.button_label}}
                @translatedTitle={{setting_button.button_title}}
  
                class="btn-text"
              />
            {{/if}}
          {{else}}
            {{#if (eq @topic.canEditTags true)}}
              <DButton
                @action={{fn (this.addTag setting_button)}}
                @icon="tag"
                {{! @label={{themePrefix "quick_add_tag_button_text"}}
                {{! @title={{themePrefix "quick_add_tag_button_title"}}
                @translatedLabel={{setting_button.button_label}}
                @translatedTitle={{setting_button.button_title}}
  
                class="btn-text"
              />
            {{/if}}
          {{/if}}
        {{/if}}
      {{else}}
        {{#if setting_button.auto_close_topic}}
          {{#if (or this.currentUser.moderator this.currentUser.admin (eq this.currentUser.trust_level 4))}}
            <DButton
              @action={{fn (this.addTag setting_button)}}
              @icon="tag"
              {{! @label={{themePrefix "quick_add_tag_button_text"}}
              {{! @title={{themePrefix "quick_add_tag_button_title"}}
              @translatedLabel={{setting_button.button_label}}
              @translatedTitle={{setting_button.button_title}}

              class="btn-text"
            />
          {{/if}}
        {{else}}
          {{#if (eq @topic.canEditTags true)}}
            <DButton
              @action={{fn (this.addTag setting_button)}}
              @icon="tag"
              {{! @label={{themePrefix "quick_add_tag_button_text"}}
              {{! @title={{themePrefix "quick_add_tag_button_title"}}
              @translatedLabel={{setting_button.button_label}}
              @translatedTitle={{setting_button.button_title}}

              class="btn-text"
            />
          {{/if}}
        {{/if}}
      {{/if}}
    {{/each}}
  </template>
}
