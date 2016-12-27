import React, { Component } from 'react';

class SearchForm extends Component {
  constructor(props) {
    super(props);
    this.state = { value: '' };
    this.handleChange = this.handleChange.bind(this);
    this.handleClick = this.handleClick.bind(this);
  }

  handleChange(event) {
    const value = event.target.value;
    this.setState({ value: value });
  }

  handleClick(event) {
    this.props.addFolder(this.state.value);
  }

  render() {
    return (
      <div>
        <div className="input-group mt-1">
          <input className="form-control form-control-sm"
            type="text"
            placeholder="Search or folder name"
            value={this.state.value}
            onChange={this.handleChange}
          />
          <span className="input-group-btn">
            <button className="btn btn-secondary btn-sm"
              type="button"
              onClick={this.handleClick}>
              Create folder
            </button>
          </span>
        </div>
        {this.state.error &&
          <p className="text-danger mt-1">
            Folder name can't contain slashes
          </p>
        }
      </div>
    );
  }
}

export default SearchForm;