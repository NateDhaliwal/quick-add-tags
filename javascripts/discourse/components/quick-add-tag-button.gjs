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

  @tracked allowed_groups = [];

  constructor() {
    super(...arguments);
    let user_groups = []
    console.log(this.currentUser);
    for (let grp in this.currentUser.groups) {
      user_groups.push(grp.id);
    }
    // Pre-fill the allowed_groups array with false values; they will be replaced with `true` values
    // when the loop checks if any of the user's own groups are in the setting's allowed groups
    for (let settingIndex in settings.quick_add_tags_buttons) {
      this.allowed_groups[settingIndex] = false; // Or .push()
    }

    // Here, we iterate through the settings and iterate through each of that to check if the user is inside.
    for (let setting of settings.quick_add_tags_buttons) {
      for (let setting_group of setting.show_for_groups) {
        if (user_groups.includes(setting_group)) {
          this.allowed_groups[settings.quick_add_tags_buttons.indexOf(setting)] = true;
        }
      }
    }
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
    {{#each settings.quick_add_tags_buttons as |setting_button index|}}
      {{#if true}}
        {{log this.allowed_groups}}
        {{log index}}
        {{log this.allowed_grousp[index]}}
        <h1>{{this.allowed_groups.[index]}}</h1>
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
      {{/if}}
    {{/each}}
  </template>
}
