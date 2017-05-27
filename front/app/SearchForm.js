import React, { Component } from 'react';
import axios from 'axios';

function Result(props) {
  return (
    <a className="list-group-item list-group-item-action"
      target="_blank"
      href={props.api + props.root + '/' + props.name}>
      {props.name}
    </a>
  );
}

class SearchForm extends Component {
  constructor(props) {
    super(props);
    this.state = { value: '' , results: []};
    this.handleChange = this.handleChange.bind(this);
    this.handleClick = this.handleClick.bind(this);
    this.search = this.search.bind(this);
  }

  handleChange(event) {
    const value = event.target.value;
    this.setState({ value: value });
    if (value) {
      this.search(value);
    } else {
      this.setState({ results: [] });
    }
  }

  handleClick(event) {
    this.props.addFolder(this.state.value);
    this.setState({ value: '' });
  }

  search(str) {
    axios.get('find/?find=' + str)
      .then(res => {
        this.setState({ results: res.data.results });
      })
      .catch(err => {
        this.props.setError("Searching failed: " + err);
      });
  }

  render() {
    var results = [];
    this.state.results.forEach(result => {
      results.push(<Result
        name={result}
        key={result}
        api={this.props.api}
        root={this.props.root}
        />
      );
    });
    return (
      <div>
        <div className="input-group mt-2">
          <input className="form-control"
            type="text"
            placeholder="Search or folder name"
            value={this.state.value}
            onChange={this.handleChange}
          />
          <span className="input-group-btn">
            <button className="btn btn-secondary"
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
        <div className="mt-1 list-group">
          {results}
        </div>
      </div>
    );
  }
}

export default SearchForm;
